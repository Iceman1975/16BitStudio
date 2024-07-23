PImage img;
QImage qimg256, qimg64, qimg16;

void setup() {
  size(520, 400);
  img = loadImage("london.jpg");
  textSize(14);
  fill(0);
  background(255);
  // Make sonme quantized images
  qimg256 = new QImage(img, 256);
  qimg64 = new QImage(img, 64);
  qimg16 = new QImage(img, 16);

  text("32 bit ARGB", 10, 18);
  image(img, 0, 20);
  text("256 colors", 270, 18);
  image(qimg256.getImage(), 260, 20);

  text("64 colors", 10, 218);
  image(qimg64.getImage(), 0, 220);
  text("16 colors", 270, 218);
  image(qimg16.getImage(), 260, 220);
  save("sample.png");
}

/**
 This class is used to store the result of the image quantization.
 The final image comprises a color table and a 2D array containing 
 an index into the color table.
 It also creates a new PImage with the reduced color set for 
 convenience.
 */
public class QImage {
  final int[][] pixels;
  final int w, h;
  final int[] colortable;
  final PImage reducedImage;

  /**
   img = the PImage we want to quantize
   maxNbrColors - color table size
   */
  public QImage(PImage img, int maxNbrColors) {
    // Pixel data needs to be in 2D array for Quantize class.
    w = img.width;
    h = img.height;
    pixels = new int[h][w];
    img.loadPixels();
    int[] p = img.pixels;
    int n = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        pixels[y][x] = p[n++];
      }
    } 
    // Quantize the image
    colortable = Quantize.quantizeImage(pixels, maxNbrColors);
    //Create a PImage with the reduced color pallette
    reducedImage = createImage(w, h, ARGB);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        reducedImage.set(x, y, colortable[pixels[y][x]]);
      }
    }
  }

  /**
   Convenience method to draw the quatized image at a 
   given position.
   */
  public void displayRAW(int px, int py) {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        set(px + x, py+y, colortable[pixels[y][x]]);
      }
    }
  }

  /**
   Get the pixel color index data
   */
  public int[][] getPixels() {
    return pixels;
  }

  /**
   Get the color table data
   */
  public int[] getColorTable() {
    return colortable;
  }

  /**
   Get the maximum number of colors in the reduced image.
   The actual number of unique colors maybe less than this.
   */
  public int nbrColors() {
    return colortable.length;
  }

  /**
   Convenience method to get the quatized image as a PImage
   that can be used directly in processing
   */
  public PImage getImage() {
    return reducedImage;
  }
}
