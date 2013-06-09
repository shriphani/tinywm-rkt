 #include <X11/Xlib.h>
 #include <stdio.h>
 #include <stdlib.h>

Display* display;

int main(){
  display = XOpenDisplay("");
  printf("Success!\n");
  XCloseDisplay(display);
}
