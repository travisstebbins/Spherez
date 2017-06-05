public class Sphere {
  // public variables
  public static final float DIAMETER = 15;
  public static final float SPEED = 12;
  
  // private variables
  private Vector2 position;
  private Vector2 velocity;
  private int bounceDelay;
  
  // default constructor
  Sphere () {
    position = new Vector2();
    velocity = new Vector2();
    bounceDelay = 0;
  }
  // constructors
  Sphere (Vector2 pos, Vector2 vel) {
    position = pos;
    velocity = vel;
    bounceDelay = 0;
  }
  Sphere (float x, float y, float velX, float velY) {
    position = new Vector2 (x, y);
    velocity = new Vector2 (velX, velY);
    bounceDelay = 0;
  }
  
  // getter methods
  public Vector2 getPosition () { return position; }
  public Vector2 getVelocity () { return velocity; }
  public int getBounceDelay () { return bounceDelay; }
  
  // setter methods
  public void setPosition (Vector2 pos) { position = pos; }
  public void setVelocity (Vector2 vel) { velocity = vel; }
  public void setPosition (float x, float y) { position = new Vector2 (x, y); }
  public void setVelocity (float x, float y) { velocity = new Vector2 (x, y); }
  public void setBounceDelay (int bounceDelay) { this.bounceDelay = bounceDelay; }
  
  // helper methods
  public void updatePosition () {
    position.x += velocity.x;
    position.y += velocity.y;
  }
  public void bounceX () {
    velocity.x *= -1; 
  }
  public void bounceY () {
    velocity.y *= -1; 
  }
  
}