package vn.thoxay.weather;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;

/** No database transaction during provider I/O. Bounded LRU, single-flight per area and short error cache. */
@Service @RequiredArgsConstructor
public class WeatherService {
    private final WeatherProvider provider;
    private final Clock clock;
    private record Area(long lat,long lng) { double latitude(){return lat/100.0;} double longitude(){return lng/100.0;} }
    private record Entry(WeatherReport report,Instant expires) { }
    private final Map<Area,Entry> cache=new LinkedHashMap<>(128,.75f,true);
    private final Map<Area,CompletableFuture<WeatherReport>> pending=new HashMap<>();
    public WeatherReport weather(double latitude,double longitude) {
        Area area=new Area(Math.round(latitude*100),Math.round(longitude*100));
        Instant now=clock.instant(); Entry previous; CompletableFuture<WeatherReport> future; boolean owner=false;
        synchronized(cache) {
            previous=cache.get(area);
            if(previous!=null&&previous.expires().isAfter(now)) return previous.report();
            future=pending.get(area);
            if(future==null) {
                if(pending.size()>=8) return fallback(area,previous,now);
                future=new CompletableFuture<>(); pending.put(area,future); owner=true;
            }
        }
        if(!owner) {
            try { return future.get(3500,TimeUnit.MILLISECONDS); }
            catch(InterruptedException e) { Thread.currentThread().interrupt(); return fallback(area,previous,now); }
            catch(ExecutionException|TimeoutException e) { return fallback(area,previous,now); }
        }
        WeatherReport report;
        try {
            var observation=provider.fetch(area.latitude(),area.longitude());
            report=observation==null ? fallback(area,previous,now) : new WeatherReport(true,false,area.latitude(),area.longitude(),observation,clock.instant(),"https://open-meteo.com/");
        } catch(Exception e) {
            if(e instanceof InterruptedException) Thread.currentThread().interrupt();
            report=fallback(area,previous,clock.instant());
        }
        synchronized(cache) {
            Duration ttl=report.available()&&!report.stale()?Duration.ofMinutes(15):Duration.ofSeconds(30);
            cache.put(area,new Entry(report,clock.instant().plus(ttl)));
            while(cache.size()>128) cache.remove(cache.keySet().iterator().next());
            pending.remove(area); future.complete(report);
        }
        return report;
    }
    private WeatherReport fallback(Area area,Entry entry,Instant now) {
        WeatherReport old=entry==null?null:entry.report();
        if(old!=null&&old.available()&&old.fetchedAt().plus(Duration.ofHours(3)).isAfter(now))
            return new WeatherReport(true,true,area.latitude(),area.longitude(),old.current(),old.fetchedAt(),old.sourceUrl());
        return new WeatherReport(false,false,area.latitude(),area.longitude(),null,now,"https://open-meteo.com/");
    }
}
