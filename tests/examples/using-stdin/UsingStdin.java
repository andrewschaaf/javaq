package com.example;

import java.io.*;
import java.util.*;

public class UsingStdin {
  public static void main(String[] args) throws Exception {
    PrintStream out = new PrintStream(System.out, true, "UTF-8");
    InputStreamReader isr = new InputStreamReader(System.in, "UTF-8");
    out.println("HAI " + isr.read());
  }
}
