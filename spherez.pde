import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

// screen properties
final int WIDTH = 405;
final int HEIGHT = 720;
int targetFrameRate = 60;

// UI properties
final int TOPPANELHEIGHT = 75;
color backgroundColor;
color topPanelColor;
final float BLOCKTEXTSIZE = 20;
final float LEVELTEXTSIZE = 50;
final float NUMSPHERESTEXTSIZE = 15;
final float MAXGUIDELENGTH = 500;
final float MAXGUIDESIZE = Sphere.DIAMETER / 2.0;
final int NUMGUIDESPHERES = 14;
final float BLOCKFADESPEED = 10;
float [][] boardSaturation;
ArrayList <Sphere> expiredSpheres;

// board properties
  // board array and number of rows and columns
    int [][] board;
    int numRows = 11;
    int numCols = 7;
  // # of pixels surrounding each block
    final float BUFFERSIZE = 5;
  // size of block (cell size - buffer) and size of cell
    float blockSize = (WIDTH - ((numCols + 1) * BUFFERSIZE)) / (float)numCols;
    float cellSize = ((float)WIDTH / numCols);
  // size of sphere up
    float sphereUpSize = blockSize / 1.5;

// player properties
  // holds spheres when they're launched
    ArrayList <Sphere> spheres;
  // number of spheres player has
    int numSpheres = 1;
    int numSpheresUps = 0;
  // launch delay (in frames)
    final float SPHEREDELAY = 4;
  // number of spheres that have been launched
    int numLaunched = 0;
  // variables to control launching/landing of spheres
    boolean firstLanded = false;
    float sphereX = WIDTH / 2;
    boolean canPlay = true;
    boolean canFire = true;
  // aiming variables
    boolean mouseClicked = false;
    Vector2 clickStart;
    Vector2 clickEnd;
    float angle = -HALF_PI;
    final float AIMSPEED = 0.05;
  // miscellaneous variables
    int level = 1;
    color sphereColor;
    
// readers/writers
PrintWriter output;
BufferedReader reader;
String line;
int highScore = 0;

// sound objects
Minim myMinim;
AudioPlayer mySound;

void setup () {
  // set up properties
  size(405, 720);
  background(0);
  noStroke();
  colorMode(HSB);
  frameRate(targetFrameRate);
  
  // set up board
  board = new int [numRows][numCols];
  boardSaturation = new float [numRows][numCols];
  // set all saturatios to be 255
  for (int r = 0; r < numRows; ++r) {
    for (int c = 0; c < numCols; ++c) {
      boardSaturation[r][c] = 255;
    }
  }
  // spawn blocks in first 2 rows
  for (int r = 1; r < 3; ++r) {
    for (int c = 0; c < numCols; ++c) {
      int spawnBlock = int(random(0, 2));
      if (spawnBlock == 1) {
        board[r][c] = int(random(0, (2 * level) + 1));
      }
    }
  }
  // set up variables
  spheres = new ArrayList<Sphere>();
  expiredSpheres = new ArrayList<Sphere>();
  sphereColor = color(0, 0, 255);
  backgroundColor = color(0, 0, 25);
  topPanelColor = color(0, 0, 50);
  // read in current high score
  reader = createReader("highScore.txt");
  try {
    line = reader.readLine(); 
  } catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  if (line != null) {
    highScore = int(line);
  }
  // create text file writer
  output = createWriter("highScore.txt");
  // set up sound objects
  myMinim = new Minim(this);
  mySound = myMinim.loadFile("blop.wav");
  // call function to set-up handling of user closing app
  prepareExitHandler();
}

void draw () {
  drawScreen();
}

void drawScreen () {
  background(backgroundColor);
  drawBoard();
  drawSpheres();
  drawUI();
}

void drawUI () {
  // drop the top panel
  fill(topPanelColor);
  rect(0, 0, WIDTH, TOPPANELHEIGHT);
  fill(255);
  textSize(LEVELTEXTSIZE);
  textAlign(CENTER);
  text(level, WIDTH / 2.0, (TOPPANELHEIGHT / 2.0) + (LEVELTEXTSIZE / 3.0));
  textSize(LEVELTEXTSIZE / 3.0);
  text("BEST", 50, 30);
  textSize(LEVELTEXTSIZE / 2.0);
  text(highScore, 50, 60);
  // draw guide-line for firing
  if (mouseClicked) {
     // get the mouse's current position
     clickEnd = new Vector2(mouseX, mouseY); 
     // find vector from click start to click end
     Vector2 resultant = new Vector2 (clickStart.x - clickEnd.x, clickEnd.y - clickStart.y);
     // convert to unit vector
     Vector2 unit = resultant.unitVector();
     // get the angle and adjust it
     angle = atan(unit.x / unit.y);
     angle -= HALF_PI;
     // if the user is in a proper position to fire, draw the guideline and allow them to do so
     if (unit.y > 0 && angle < -PI / 40.0 && angle > (-PI + (PI / 40.0))) {
       canFire = true;
       stroke(0, 0, 255);
       // set the guide length
       float guideLength = resultant.magnitude() > MAXGUIDELENGTH ? MAXGUIDELENGTH : resultant.magnitude();
       // draw the guide
       drawGuide(sphereX, HEIGHT - Sphere.DIAMETER / 2.0, sphereX + (guideLength * cos(angle)), HEIGHT - Sphere.DIAMETER / 2.0 + (guideLength * sin(angle)));
       noStroke();
     }
     // if the user isn't in a proper position, don't let them fire
     else {
       canFire = false;
     }
  }
}

void drawGuide (float x1, float y1, float x2, float y2) {
  Vector2 resultant = new Vector2(x2 - x1, y2 - y1);
  float magnitude = resultant.magnitude();
  for (int i = 0; i < NUMGUIDESPHERES; i++) {
    float x = lerp(x1, x2, i / (float)NUMGUIDESPHERES);
    float y = lerp(y1, y2, i/(float)NUMGUIDESPHERES);
    float size = (magnitude / MAXGUIDELENGTH) * MAXGUIDESIZE;
    ellipse(x, y, size, size);
  }
}

void drawBoard () {
  // iterate through rows and columns
  for (int r = 0; r < numRows; ++r) {
    for (int c = 0; c < numCols; ++c) {
      // if there is a block, draw it
      if (board[r][c] > 0) {
        // set the block's color based on its level
        fill(board[r][c] % 255, boardSaturation[r][c], 255);
        if (boardSaturation[r][c] < 255) {
          boardSaturation[r][c] += BLOCKFADESPEED;
          if (boardSaturation[r][c] >= 255) {
            boardSaturation[r][c] = 255; 
          }
        }
        rect((c * cellSize) + BUFFERSIZE, (r * cellSize) + BUFFERSIZE + TOPPANELHEIGHT, blockSize, blockSize);
        // draw the block's level text
        fill(0);
        textSize(BLOCKTEXTSIZE);
        textAlign(CENTER);
        float x = (c * cellSize) + (cellSize / 2.0);
        float y = (r * cellSize) + (cellSize / 2.0) + TOPPANELHEIGHT + (BLOCKTEXTSIZE / 2.0);
        text(board[r][c], x, y);
      }
      // if there's a sphere-up, draw it
      else if (board[r][c] == -1) {
        drawSphereUp((c * cellSize) + (cellSize / 2.0), (r * cellSize) + (cellSize / 2.0) + TOPPANELHEIGHT);
      }
    }
  }
}

void drawSphereUp (float x, float y) {
  fill(255);
  ellipse(x + (sphereUpSize / 2.0 * cos(frameCount / 10.0)), y, 10, 10);
  ellipse(x, y + (sphereUpSize / 2.0 * cos(frameCount / 10.0)), 10, 10);
  ellipse(x - (sphereUpSize / 2.0 * cos(frameCount / 10.0)), y, 10, 10);
  ellipse(x, y - (sphereUpSize / 2.0 * cos(frameCount / 10.0)), 10, 10);
}

void drawSpheres () {
  // if the user can play (spheres aren't in play), draw sphere starting location
  if (canPlay) {
    fill(sphereColor);
    ellipse(sphereX, HEIGHT - Sphere.DIAMETER / 2.0, Sphere.DIAMETER, Sphere.DIAMETER);
    fill(255);
    textSize(NUMSPHERESTEXTSIZE);
    textAlign(CENTER);
    text("x" + numSpheres, sphereX, HEIGHT - Sphere.DIAMETER - 5);
  }
  // else, draw spheres in motion
  else {
    // if all spheres haven't been launched yet
    if (numLaunched < numSpheres) {
      // draw sphere at starting location
      fill(sphereColor);
      ellipse(sphereX, HEIGHT - Sphere.DIAMETER / 2.0, Sphere.DIAMETER, Sphere.DIAMETER);
      fill(255);
      textSize(NUMSPHERESTEXTSIZE);
      textAlign(CENTER);
      text("x" + (numSpheres - numLaunched), sphereX, HEIGHT - Sphere.DIAMETER - 5);
      // create and launch new sphere every SPHEREDELAY frames
      if (frameCount % SPHEREDELAY == 0) {
        spheres.add(new Sphere(sphereX, HEIGHT - Sphere.DIAMETER / 2.0, Sphere.SPEED * cos(angle), Sphere.SPEED * sin(angle)));
        numLaunched++;
      }
    }
    // update sphere locations
    updateSpheres();
    // draw spheres in motion
    fill(sphereColor);
    for (int i = 0; i < spheres.size(); ++i) {
      ellipse(spheres.get(i).getPosition().x, spheres.get(i).getPosition().y, Sphere.DIAMETER, Sphere.DIAMETER);
    }
    // draw expired spheres
    for (int i = 0; i < expiredSpheres.size(); ++i) {
      ellipse(expiredSpheres.get(i).getPosition().x, expiredSpheres.get(i).getPosition().y, Sphere.DIAMETER, Sphere.DIAMETER);
    }
    // if the first sphere has landed
    if (firstLanded) {
      // draw a sphere at the new starting location
      fill(sphereColor);
      ellipse(sphereX, HEIGHT - Sphere.DIAMETER / 2.0, Sphere.DIAMETER, Sphere.DIAMETER);
    }
  }
}

// handles physics of all spheres
void updateSpheres () {
  // iterate through all spheres
  for (int i = 0; i < spheres.size(); ++i) {
    // update sphere position based on velocity
    spheres.get(i).updatePosition();
    // check if sphere has collided with a block
    int[] col = collision(spheres.get(i));
    // if sphere can bounce
    if (spheres.get(i).getBounceDelay() == 0) {
      // and if sphere has collided with a block
      if (col[0] >= 0 && board[col[0]][col[1]] > 0) {
        // get vector components from collided block center to sphere
        float y = spheres.get(i).getPosition().y - ((col[0] * cellSize) + (cellSize / 2.0) + TOPPANELHEIGHT);
        float x = spheres.get(i).getPosition().x - ((col[1] * cellSize) + (cellSize / 2.0));
        float tan = y / x;
        // find angle of collision
        float angle = atan(tan);
        // if the sphere has hit the top or bottom of a block
        if ((PI / 4.0 <= angle && angle <= 3 * PI / 4.0) || (-3 * PI / 4.0 <= angle && angle <= -PI / 4.0)) {
          // bounce sphere in y direction
          spheres.get(i).bounceY();
          // set sphere bounce delay (prevents sphere from hitting block more than once at a time)
          spheres.get(i).setBounceDelay(1);
          // reduce block value
          board[col[0]][col[1]]--;
        }
        // else if the sphere has hit the left or right side of a block
        else {
          // bounce sphere in x direction
          spheres.get(i).bounceX();
          // set sphere bounce delay (prevents sphere from hitting block more than once at a time)
          spheres.get(i).setBounceDelay(1);
          // reduce block value
          board[col[0]][col[1]]--;
        }
        boardSaturation[col[0]][col[1]] = 0;
        mySound.rewind();
        mySound.play();
      }
    }
    // if sphere can't bounce, decrement bounce delay
    else {
       spheres.get(i).setBounceDelay(spheres.get(i).getBounceDelay() - 1);
    }
    // if sphere has collided with sphere-up
    if (col[0] >= 0 && board[col[0]][col[1]] == -1) {
      // check more precisely for collision
      if (distance(spheres.get(i).getPosition().x, spheres.get(i).getPosition().y, (col[1] * cellSize) + (cellSize / 2.0), (col[0] * cellSize) + (cellSize / 2.0) + TOPPANELHEIGHT) 
        <= (Sphere.DIAMETER / 2.0) + (sphereUpSize / 2.0)) {
          // increment numSphereUps
          numSpheresUps++;
          // remove sphere-up from board
          board[col[0]][col[1]] = 0;
      }
    }
    // if sphere has hit left or right edge
    if (spheres.get(i).getPosition().x < Sphere.DIAMETER / 2.0 || spheres.get(i).getPosition().x > WIDTH - (Sphere.DIAMETER / 2.0)) {
      // bounce in x direction
      spheres.get(i).bounceX();
    }
    // if sphere has hit top edge
    if (spheres.get(i).getPosition().y < TOPPANELHEIGHT + Sphere.DIAMETER) {
      // bounce in y direction
      spheres.get(i).bounceY(); 
    }
    // else if sphere has hit bottom
    else if (spheres.get(i).getPosition().y > HEIGHT - Sphere.DIAMETER / 2.0) {
      // if it is the first sphere to hit the bottom
      if (spheres.size() == numSpheres) {
        // update new starting position
        sphereX = spheres.get(i).getPosition().x;
        firstLanded = true;
      }
      else {
        // add sphere to expired sphere array list
        expiredSpheres.add(new Sphere(spheres.get(i).getPosition().x, HEIGHT - Sphere.DIAMETER / 2.0, spheres.get(i).getPosition().x > sphereX ? -Sphere.SPEED : Sphere.SPEED, 0));
      }
      // remove sphere from array list
      spheres.remove(i);
      // if it is the last sphere
      if (spheres.size() == 0) {
        // reset playing variables and advance level
        //angle = -HALF_PI;
        //canPlay = true;
        //numLaunched = 0;
        //firstLanded = false;
        //advanceLevel();
      }
    }
  }
  // iterate through all expired spheres
  for (int i = 0; i < expiredSpheres.size(); ++i) {
    expiredSpheres.get(i).updatePosition();
    if (expiredSpheres.get(i).getVelocity().x > 0 && expiredSpheres.get(i).getPosition().x >= sphereX) {
      expiredSpheres.remove(i); 
    }
    else if (expiredSpheres.get(i).getVelocity().x < 0 && expiredSpheres.get(i).getPosition().x <= sphereX) {
      expiredSpheres.remove(i); 
    }
  }
  if (spheres.size() == 0 && expiredSpheres.size() == 0 && numLaunched == numSpheres) {
    // reset playing variables and advance level
    angle = -HALF_PI;
    canPlay = true;
    numLaunched = 0;
    firstLanded = false;
    advanceLevel();
  }
}

// handles sphere collision with blocks and sphere-ups
int[] collision (Sphere s) {
   // array A holds indices of possible collision
   int[] A = {-1, -1};
   // points c1 to c3 and r1 to r3 check for collisions along points of sphere
   int c1, r1, c2, r2, c3, r3;
   // if sphere is moving right
   if (s.getVelocity().x > 0) {
     // get right point of circle
     c1 = (int) (ceil((s.getPosition().x + (Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
     r1 = (int) ((s.getPosition().y - TOPPANELHEIGHT) / cellSize);
     // if sphere is moving up
     if (s.getVelocity().y < 0) {
       // get top point of circle
       c2 =  (int) (ceil(s.getPosition().x / cellSize)) - 1;
       r2 = (int) ((s.getPosition().y - (Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
       // get top right point of circle
       c3 = (int) (ceil((s.getPosition().x + (cos(HALF_PI) * Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
       r3 = (int) ((s.getPosition().y - (sin(HALF_PI) * Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
     }
     // else if sphere is moving down
     else {
       // get bottom point of circle
       c2 = (int) (ceil(s.getPosition().x / cellSize)) - 1;
       r2 = (int) ((s.getPosition().y + (Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT / cellSize));
       // get bottom right point of circle
       c3 = (int) (ceil((s.getPosition().x + (cos(HALF_PI) * Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
       r3 = (int) ((s.getPosition().y + (sin(HALF_PI) * Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
     }
   }
   // else if sphere is moving left
   else {
     // get left point of circle
     c1 = (int) (ceil((s.getPosition().x - (Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
     r1 = (int) ((s.getPosition().y - TOPPANELHEIGHT) / cellSize);
     // if sphere is moving up
     if (s.getVelocity().y < 0) {
       // get top point of circle
       c2 =  (int) (ceil(s.getPosition().x / cellSize)) - 1;
       r2 = (int) ((s.getPosition().y - (Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
       // get top left point of circle
       c3 = (int) (ceil((s.getPosition().x - (cos(HALF_PI) * Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
       r3 = (int) ((s.getPosition().y - (sin(HALF_PI) * Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
     }
     // else if sphere is moving down
     else {
       // get bottom point of circle
       c2 = (int) (ceil(s.getPosition().x / cellSize)) - 1;
       r2 = (int) ((s.getPosition().y + (Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT / cellSize));
       // get bottom left point of circle
       c3 = (int) (ceil((s.getPosition().x - (cos(HALF_PI) * Sphere.DIAMETER / 2.0)) / cellSize)) - 1;
       r3 = (int) ((s.getPosition().y + (sin(HALF_PI) * Sphere.DIAMETER / 2.0) - TOPPANELHEIGHT) / cellSize);
     }
   }
   // if point (r1, c1) collides with a block or sphere-up
   if (r1 >= 0 && c1 >= 0 && r1 < numRows && c1 < numCols && board[r1][c1] != 0) {
     A[0] = r1;
     A[1] = c1;
     return A;
   }
   // if point (r2, c2) collides with a block or sphere-up
   else if (r2 >= 0 && c2 >= 0 && r2 < numRows && c2 < numCols && board[r2][c2] != 0) {
     A[0] = r2;
     A[1] = c2;
     return A;
   }
   // else if point (r3, c3) collides with a block or sphere-up
   else if (r3 >= 0 && c3 >= 0 && r3 < numRows && c3 < numCols && board[r3][c3] != 0) {
     A[0] = r3;
     A[1] = c3;
     return A;
   }
   return A;
}

void advanceLevel() {
  // increment level
  ++level;
  // return game speed to normal
  targetFrameRate = 60;
  frameRate(targetFrameRate);
  // add spheres to user if they collected sphere-ups and reset numSphereUps
  numSpheres += numSpheresUps;
  numSpheresUps = 0;
  // shift all blocks down
  for (int r = numRows - 1; r > 0; --r) {
    for (int c = 0; c < numCols; ++c) {
      board[r][c] = board[r - 1][c];
      boardSaturation[r][c] = boardSaturation[r - 1][c];
    }
  }
  // generate sphere-up
  int sphereSpawn = int(random(0, numCols));
  board[1][sphereSpawn] = -1;
  // generate new blocks
  for (int c = 0; c < numCols; ++c) {
    int spawnBlock = int(random(0, 2));
      if (spawnBlock == 1 && board[1][c] == 0) {
        int blockValue = int(random(0, 3));
        if (blockValue <= 1) {
          board[1][c] = level;
        }
        else {
          board[1][c] = 2 * level; 
        }
      }
  }
  // check to see if the game is over (a block has hit the bottom)
  for (int c = 0; c < numCols; ++c) {
    if (board[numRows - 1][c] > 0) {
      endGame();
    }
  }
}

// called when the game is over
void endGame () {
  exit();
}

// handle user clicking mouse down
void mousePressed () {
  if (canPlay && !mouseClicked && mouseButton == LEFT) {
    clickStart = new Vector2(mouseX, mouseY);
    mouseClicked = true;
  }
}

// handles user release mouse
void mouseReleased () {
  // if the player is in a position to fire, do so
  if (canPlay && canFire && mouseClicked && mouseButton == LEFT) {
    mouseClicked = false;
    clickEnd = new Vector2(mouseX, mouseY);
    canPlay = false;
    canFire = false;
  }
  // else unclick the mouse
  else {
    mouseClicked = false; 
  }
}

void keyPressed () {
  // if user hits 'f' key
  if (key == 'f') {
    // toggle target frame rate
    if (targetFrameRate == 60) {
      targetFrameRate = 180;
    }
    else {
      targetFrameRate = 60;
    }
    frameRate(targetFrameRate);
  }
}

// calculates distance between points (x1, y1) and (x2, y2)
double distance (float x1, float y1, float x2, float y2) {
  return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}

// sets up thread to run onExit() when user exits
private void prepareExitHandler () {
  Runtime.getRuntime().addShutdownHook(
    new Thread(
      new Runnable() {
        public void run () {
          onExit();
        }
      }
    )
  );
}

// prints high score to file
void onExit () {
  if (level > highScore) {
    output.println(level);
  }
  else {
    output.println(highScore); 
  }
  output.flush();
  output.close();
}