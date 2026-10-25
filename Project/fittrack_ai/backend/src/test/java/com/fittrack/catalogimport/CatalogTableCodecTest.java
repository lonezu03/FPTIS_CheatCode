package com.fittrack.catalogimport;

import org.junit.jupiter.api.Test;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.io.ByteArrayOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import static org.assertj.core.api.Assertions.*;

class CatalogTableCodecTest {
    @Test void parsesQuotedCsvAndPastedTabs(){
        assertThat(CatalogTableCodec.delimited("name,description\n\"A, B\",\"Dòng 1\nDòng 2\"\n")).containsExactly(List.of("name","description"),List.of("A, B","Dòng 1\nDòng 2"));
        assertThat(CatalogTableCodec.delimited("name\tequipment\nSquat\tSmith")).containsExactly(List.of("name","equipment"),List.of("Squat","Smith"));
    }
    @Test void boundsRowsAndMalformedQuotes(){
        assertThatThrownBy(()->CatalogTableCodec.delimited("name\n"+"test\n".repeat(501))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(()->CatalogTableCodec.delimited("name\n\"broken")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(()->CatalogTableCodec.read(new byte[2_000_001],"x.csv")).isInstanceOf(IllegalArgumentException.class);
    }
    @Test void xlsxRoundtripIsDataOnlyAndCsvIsFormulaSafe(){
        var rows=List.of(List.of("name","description"),List.of("Tiếng Việt & <>","=cmd()"));
        assertThat(CatalogTableCodec.read(CatalogTableCodec.workbook(rows),"test.xlsx")).isEqualTo(rows);
        assertThat(CatalogTableCodec.csv(rows)).contains("'=cmd()");
        assertThatThrownBy(()->CatalogTableCodec.read("not excel".getBytes(StandardCharsets.UTF_8),"bad.xlsx")).isInstanceOf(IllegalArgumentException.class);
    }
    @Test void rejectsFormulasMacrosAndExpansionBombs() throws Exception {
        assertThatThrownBy(()->CatalogTableCodec.read(zip("xl/worksheets/sheet1.xml","<worksheet><sheetData><row><c r=\"A1\"><f>1+1</f><v>2</v></c></row></sheetData></worksheet>"),"x.xlsx")).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("công thức");
        assertThatThrownBy(()->CatalogTableCodec.read(zip("xl/vbaProject.bin","macro"),"x.xlsx")).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("macro");
        assertThatThrownBy(()->CatalogTableCodec.read(zip("xl/worksheets/sheet1.xml","x".repeat(5_000_001)),"x.xlsx")).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("quá lớn");
        assertThatThrownBy(()->CatalogTableCodec.read(zip("xl/worksheets/sheet1.xml","<!DOCTYPE foo [<!ENTITY xxe SYSTEM 'file:///etc/passwd'>]><worksheet><row><c r=\"A1\" t=\"inlineStr\"><is><t>&xxe;</t></is></c></row></worksheet>"),"x.xlsx")).isInstanceOf(IllegalArgumentException.class);
    }
    private byte[] zip(String name,String text)throws Exception {var out=new ByteArrayOutputStream();try(var z=new ZipOutputStream(out)){z.putNextEntry(new ZipEntry(name));z.write(text.getBytes(StandardCharsets.UTF_8));z.closeEntry();}return out.toByteArray();}
}
