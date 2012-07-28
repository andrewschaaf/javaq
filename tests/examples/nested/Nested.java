package com.example;

import java.io.*;
import com.example.asdf.*;

public class Nested {
  public static void main(String[] args) throws Exception {
    PrintStream out = new PrintStream(System.out, true, "UTF-8");
    out.println(Foo.FOO + " " + Bar.BAR);
  }
}
