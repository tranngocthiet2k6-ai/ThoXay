package vn.thoxay.wallet;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
/** NAPAS account transfer TLV (QRIBFTTA), generated locally; beneficiary name is displayed separately. */
public final class VietQrPayload {
 private VietQrPayload(){}
 public static String build(String bin,String account,long amount,String reference){
  if(bin==null||!bin.matches("[0-9]{6}")||account==null||!account.matches("[A-Za-z0-9]{1,19}")||amount<1||amount>9999999999999L||reference==null||!reference.matches("[A-Z0-9]{1,25}"))throw new IllegalArgumentException("Invalid VietQR account transfer fields");
  String beneficiary=tlv("00",bin)+tlv("01",account);
  String merchant=tlv("00","A000000727")+tlv("01",beneficiary)+tlv("02","QRIBFTTA");
  String payload=tlv("00","01")+tlv("01","12")+tlv("38",merchant)+tlv("53","704")+tlv("54",Long.toString(amount))+tlv("58","VN")+tlv("62",tlv("08",reference))+"6304";
  return payload+String.format(Locale.ROOT,"%04X",crc(payload));
 }
 private static String tlv(String id,String value){int length=value.getBytes(StandardCharsets.US_ASCII).length;if(length>99)throw new IllegalArgumentException("TLV field too long");return id+String.format(Locale.ROOT,"%02d",length)+value;}
 static int crc(String value){int crc=0xFFFF;for(byte b:value.getBytes(StandardCharsets.US_ASCII)){crc^=(b&0xFF)<<8;for(int i=0;i<8;i++)crc=((crc&0x8000)!=0?(crc<<1)^0x1021:crc<<1)&0xFFFF;}return crc;}
}
