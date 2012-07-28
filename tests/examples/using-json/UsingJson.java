package com.example;

import java.io.*;
import org.json.JSONObject;

public class UsingJson {
  public static void main(String[] args) throws Exception {
    PrintStream out = new PrintStream(System.out, true, "UTF-8");
    Reader in = new InputStreamReader(System.in, "UTF-8");
    
    JSONObject info = new JSONObject();
    info.put("foo", 123);
    info.put("bar", "...");
    out.println(info.toString());
  }
}
