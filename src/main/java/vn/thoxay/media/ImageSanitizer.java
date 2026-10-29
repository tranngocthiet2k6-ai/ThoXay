package vn.thoxay.media;

import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.HttpStatus;
import vn.thoxay.exception.ApiException;
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;

/** Decode/re-encode JPEG/PNG only; strip EXIF, bound pixels before decoding and bytes after encoding. */
@Component
public class ImageSanitizer {
 public byte[] kyc(MultipartFile file){return sanitize(file,200,320,6000,5*1024*1024);}
 public byte[] project(MultipartFile file){return sanitize(file,160,240,1800,2*1024*1024);}
 private byte[] sanitize(MultipartFile file,int minShort,int minLong,int resize,int maxOutput){
  if(file==null||file.isEmpty())throw bad("Cần chọn ảnh JPEG hoặc PNG");
  if(file.getSize()>5*1024*1024)throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE,"Mỗi ảnh tải lên tối đa 5 MB");
  try(var input=new javax.imageio.stream.MemoryCacheImageInputStream(new ByteArrayInputStream(file.getBytes()))){
   var readers=ImageIO.getImageReaders(input);if(!readers.hasNext())throw bad("Ảnh phải là JPEG hoặc PNG hợp lệ");var reader=readers.next();
   try{
    var format=reader.getFormatName();if(!format.equalsIgnoreCase("JPEG")&&!format.equalsIgnoreCase("PNG"))throw bad("Chỉ hỗ trợ JPEG hoặc PNG");
    reader.setInput(input,true,true);int w=reader.getWidth(0),h=reader.getHeight(0);
    if(Math.min(w,h)<minShort||Math.max(w,h)<minLong||w>6000||h>6000||(long)w*h>16000000)throw bad("Ảnh quá nhỏ hoặc quá lớn; chọn ảnh rõ nét, không quá 16 triệu điểm ảnh / 6000 px mỗi cạnh");
    double scale=Math.min(1.0,(double)resize/Math.max(w,h));int outW=Math.max(1,(int)Math.round(w*scale)),outH=Math.max(1,(int)Math.round(h*scale));
    var source=reader.read(0);var clean=new BufferedImage(outW,outH,BufferedImage.TYPE_INT_RGB);var g=clean.createGraphics();
    try{g.setColor(Color.WHITE);g.fillRect(0,0,outW,outH);g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,RenderingHints.VALUE_INTERPOLATION_BILINEAR);g.drawImage(source,0,0,outW,outH,null);}finally{g.dispose();source.flush();}
    var output=new ByteArrayOutputStream();try{if(!ImageIO.write(clean,"jpg",output))throw bad("Không mã hóa được ảnh");}finally{clean.flush();}
    if(output.size()>maxOutput)throw bad("Ảnh sau xử lý quá lớn; hãy chọn ảnh khác");return output.toByteArray();
   }finally{reader.dispose();}
  }catch(IOException|IllegalArgumentException e){throw bad("Không đọc được ảnh. Hãy chọn JPEG hoặc PNG hợp lệ");}
 }
 private ApiException bad(String text){return new ApiException(HttpStatus.BAD_REQUEST,text);}
}
