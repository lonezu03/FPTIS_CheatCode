package com.fittrack.catalogimport;

import org.w3c.dom.*;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.*;

/** Bounded, data-only CSV/OOXML reader. Never evaluates formulas or fetches URLs. */
public final class CatalogTableCodec {
    private CatalogTableCodec() {}
    public static List<List<String>> read(byte[] data, String filename) {
        if(data.length>2_000_000) throw new IllegalArgumentException("File tối đa 2 MB");
        String name=filename==null?"paste.tsv":filename.toLowerCase(Locale.ROOT);
        if(name.endsWith(".xlsx")) return xlsx(data);
        if(!name.endsWith(".csv")&&!name.endsWith(".tsv"))throw new IllegalArgumentException("Chỉ nhận CSV UTF-8, XLSX hoặc bảng dán");
        try{return delimited(StandardCharsets.UTF_8.newDecoder().decode(java.nio.ByteBuffer.wrap(data)).toString());}
        catch(java.nio.charset.CharacterCodingException e){throw new IllegalArgumentException("CSV phải dùng UTF-8");}
    }
    static List<List<String>> delimited(String source) {
        if(source.chars().anyMatch(c->c<32 && c!='\n' && c!='\r' && c!='\t'))throw new IllegalArgumentException("Dữ liệu có ký tự điều khiển không hợp lệ");
        String text=source.replaceFirst("^\\uFEFF", "");
        char separator=text.lines().findFirst().orElse("").contains("\t")?'\t':',';
        List<List<String>> rows=new ArrayList<>(); List<String> row=new ArrayList<>(); StringBuilder cell=new StringBuilder(); boolean quoted=false;
        for(int i=0;i<text.length();i++) { char c=text.charAt(i);
            if(c=='"') { if(quoted && i+1<text.length() && text.charAt(i+1)=='"') {cell.append('"');i++;} else quoted=!quoted; }
            else if(!quoted && (c==separator || c=='\n')) {row.add(cell.toString());cell.setLength(0);if(c=='\n'){add(rows,row);row=new ArrayList<>();}}
            else if(c!='\r')cell.append(c);
            if(cell.length()>10000 || row.size()>50)throw new IllegalArgumentException("Ô hoặc số cột vượt giới hạn");
        }
        if(quoted)throw new IllegalArgumentException("Dấu ngoặc kép CSV chưa đóng");
        row.add(cell.toString());add(rows,row);return rows;
    }
    private static void add(List<List<String>> rows,List<String> row) { if(row.stream().anyMatch(v->!v.isBlank()))rows.add(row);if(rows.size()>501)throw new IllegalArgumentException("Tối đa 500 dòng dữ liệu"); }
    private static Document xml(byte[] bytes) throws Exception {
        var f=DocumentBuilderFactory.newInstance();f.setFeature("http://apache.org/xml/features/disallow-doctype-decl",true);f.setFeature("http://xml.org/sax/features/external-general-entities",false);f.setFeature("http://xml.org/sax/features/external-parameter-entities",false);f.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD,"");f.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA,"");return f.newDocumentBuilder().parse(new ByteArrayInputStream(bytes));
    }
    private static List<List<String>> xlsx(byte[] data) {
        try { Map<String,byte[]> entries=new HashMap<>(); int total=0,count=0;
            try(var zip=new ZipInputStream(new ByteArrayInputStream(data))){
                ZipEntry e;
                while((e=zip.getNextEntry())!=null){
                    if(++count>100)throw new IllegalArgumentException("File Excel quá phức tạp");
                    byte[] b=zip.readNBytes(5_000_001);total+=b.length;
                    if(total>5_000_000)throw new IllegalArgumentException("File Excel giải nén quá lớn");
                    if(e.getName().toLowerCase(Locale.ROOT).contains("vbaproject")||e.getName().startsWith("xl/externalLinks/"))throw new IllegalArgumentException("Không hỗ trợ macro/liên kết ngoài");
                    if(e.getName().endsWith(".rels")){
                        var links=xml(b).getElementsByTagName("Relationship");
                        for(int i=0;i<links.getLength();i++)if("External".equalsIgnoreCase(((Element)links.item(i)).getAttribute("TargetMode")))throw new IllegalArgumentException("Không hỗ trợ liên kết ngoài");
                    }
                    if(entries.put(e.getName(),b)!=null)throw new IllegalArgumentException("File Excel có mục trùng lặp");
                }
            }
            List<String> strings=new ArrayList<>(); if(entries.containsKey("xl/sharedStrings.xml")){var nodes=xml(entries.get("xl/sharedStrings.xml")).getElementsByTagName("si");for(int i=0;i<nodes.getLength();i++)strings.add(nodes.item(i).getTextContent());}
            byte[] sheet=entries.get("xl/worksheets/sheet1.xml");if(sheet==null)throw new IllegalArgumentException("Không tìm thấy trang tính đầu tiên");
            var nodes=xml(sheet).getElementsByTagName("row");List<List<String>> rows=new ArrayList<>();
            for(int i=0;i<nodes.getLength();i++){List<String> row=new ArrayList<>();var cells=((Element)nodes.item(i)).getElementsByTagName("c");for(int j=0;j<cells.getLength();j++){Element c=(Element)cells.item(j);if(c.getElementsByTagName("f").getLength()>0)throw new IllegalArgumentException("Không nhận công thức; hãy dán giá trị");String ref=c.getAttribute("r").replaceAll("[0-9]","");int col=0;for(char ch:ref.toCharArray())col=col*26+ch-'A'+1;if(col<1||col>50)throw new IllegalArgumentException("Cột Excel không hợp lệ");while(row.size()<col)row.add("");var values=c.getElementsByTagName("v");String value="inlineStr".equals(c.getAttribute("t"))?c.getTextContent():values.getLength()==0?"":values.item(0).getTextContent();if("s".equals(c.getAttribute("t")))value=strings.get(Integer.parseInt(value));if(value.length()>10000)throw new IllegalArgumentException("Ô quá dài");row.set(col-1,value);}add(rows,row);}return rows;
        }catch(IllegalArgumentException e){throw e;}catch(Exception e){throw new IllegalArgumentException("File XLSX không hợp lệ");}
    }
    public static String csv(List<List<String>> rows) {StringBuilder out=new StringBuilder("\uFEFF");for(var row:rows){out.append(row.stream().map(v->{String s=v==null?"":v;String leading=s.stripLeading();if(!leading.isEmpty()&&"=+@-".indexOf(leading.charAt(0))>=0)s="'"+s;return "\""+s.replace("\"","\"\"")+"\"";}).collect(java.util.stream.Collectors.joining(","))).append("\r\n");}return out.toString();}
    public static byte[] workbook(List<List<String>> rows) {
        try{var out=new ByteArrayOutputStream();try(var z=new ZipOutputStream(out)){entry(z,"[Content_Types].xml","<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\"><Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/><Default Extension=\"xml\" ContentType=\"application/xml\"/><Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/><Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/></Types>");entry(z,"_rels/.rels","<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/></Relationships>");entry(z,"xl/workbook.xml","<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\"><sheets><sheet name=\"Data\" sheetId=\"1\" r:id=\"rId1\"/></sheets></workbook>");entry(z,"xl/_rels/workbook.xml.rels","<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/></Relationships>");StringBuilder sheet=new StringBuilder("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>");for(int r=0;r<rows.size();r++){sheet.append("<row r=\"").append(r+1).append("\">");for(int c=0;c<rows.get(r).size();c++){int n=c+1;String col="";while(n>0){n--;col=(char)('A'+n%26)+col;n/=26;}String s=rows.get(r).get(c);sheet.append("<c r=\"").append(col).append(r+1).append("\" t=\"inlineStr\"><is><t>").append(s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")).append("</t></is></c>");}sheet.append("</row>");}entry(z,"xl/worksheets/sheet1.xml",sheet.append("</sheetData></worksheet>").toString());}return out.toByteArray();}catch(IOException e){throw new IllegalStateException(e);}
    }
    private static void entry(ZipOutputStream z,String name,String text)throws IOException {z.putNextEntry(new ZipEntry(name));z.write(text.getBytes(StandardCharsets.UTF_8));z.closeEntry();}
}
