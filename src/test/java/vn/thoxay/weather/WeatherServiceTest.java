package vn.thoxay.weather;

import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class WeatherServiceTest {
    final Clock clock=mock(Clock.class);
    final WeatherProvider provider=mock(WeatherProvider.class);
    final Instant now=Instant.parse("2026-10-29T08:00:00Z");
    final WeatherReport.Observation observation=new WeatherReport.Observation(31,36,61,1.2,12,true,now);
    WeatherService service() { when(clock.instant()).thenReturn(now);return new WeatherService(provider,clock); }
    @Test void roundsGpsAndCachesTheAreaForFifteenMinutes() throws Exception {
        var service=service(); when(provider.fetch(anyDouble(),anyDouble())).thenReturn(observation);
        var first=service.weather(10.7611,106.6611);
        assertThat(service.weather(10.7619,106.6619)).isEqualTo(first);
        verify(provider,times(1)).fetch(10.76,106.66);
        assertThat(first.latitude()).isEqualTo(10.76);assertThat(first.available()).isTrue();
        when(clock.instant()).thenReturn(now.plusSeconds(901));service.weather(10.7611,106.6611);
        verify(provider,times(2)).fetch(10.76,106.66);
    }
    @Test void providerFailureReturnsMarkedStaleDataThenExpiresItAndBacksOff() throws Exception {
        var service=service();when(provider.fetch(anyDouble(),anyDouble())).thenReturn(observation);
        service.weather(10,106);when(clock.instant()).thenReturn(now.plusSeconds(901));
        when(provider.fetch(anyDouble(),anyDouble())).thenThrow(new IllegalStateException("offline"));
        var stale=service.weather(10,106);assertThat(stale.stale()).isTrue();assertThat(stale.current()).isEqualTo(observation);
        assertThat(stale.fetchedAt()).isEqualTo(now);service.weather(10,106);verify(provider,times(2)).fetch(10,106);
        when(clock.instant()).thenReturn(now.plus(Duration.ofHours(4)));
        var expired=service.weather(10,106);assertThat(expired.available()).isFalse();assertThat(expired.current()).isNull();
        service.weather(10,106);verify(provider,times(3)).fetch(10,106);
    }
    @Test void evictsOldAreasWhenTheLruReaches128Entries() throws Exception {
        var service=service();when(provider.fetch(anyDouble(),anyDouble())).thenReturn(observation);
        for(int i=0;i<129;i++)service.weather(i/100.0,106);
        service.weather(0,106);verify(provider,times(2)).fetch(0,106);
    }
    @Test void boundsConcurrentProviderCallsAndSharesRequestsForTheSameArea() throws Exception {
        var service=service();var entered=new CountDownLatch(8);var release=new CountDownLatch(1);
        when(provider.fetch(anyDouble(),anyDouble())).thenAnswer(call->{entered.countDown();assertThat(release.await(5,TimeUnit.SECONDS)).isTrue();return observation;});
        var pool=Executors.newFixedThreadPool(10);
        try {
            var calls=new ArrayList<Future<WeatherReport>>();
            for(int i=0;i<8;i++){final int area=i;calls.add(pool.submit(()->service.weather(area,106)));}
            assertThat(entered.await(3,TimeUnit.SECONDS)).isTrue();
            var shared=pool.submit(()->service.weather(0.001,106));
            assertThat(service.weather(20,106).available()).isFalse();
            release.countDown();for(var call:calls)assertThat(call.get(5,TimeUnit.SECONDS).available()).isTrue();
            assertThat(shared.get(5,TimeUnit.SECONDS).available()).isTrue();verify(provider,times(8)).fetch(anyDouble(),anyDouble());
        }finally{release.countDown();pool.shutdownNow();}
    }
}
