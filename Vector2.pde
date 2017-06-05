public class Vector2 {
  public float x;
  public float y;
  
  // default constructor
  public Vector2 () {
    x = 0;
    y = 0;
  }
  
  // constructor
  public Vector2 (float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  // helper methods
  public float magnitude () { return (float)Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2)); }
  public Vector2 unitVector () { return new Vector2 (this.x / this.magnitude(), this.y / this.magnitude()); }
  
}