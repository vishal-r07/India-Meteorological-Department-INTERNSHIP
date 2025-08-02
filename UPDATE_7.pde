import processing.serial.*;
import java.awt.Frame;
import java.awt.event.WindowEvent;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

// === PAGE MANAGEMENT ===
int currentPage = -1; // -1=Login, 0=Home, 1=About, 2=Simulation, 3=Credits, 4=Azimuth
color bgColor = color(245, 248, 250);
color primaryColor = color(0, 82, 147); // Deep blue
color secondaryColor = color(0, 120, 215); // Medium blue
color accentColor = color(255, 136, 0); // Orange
color darkText = color(30, 30, 30);
color lightText = color(250, 250, 250);

// Scroll variables for credits page
float creditsScrollY = 0;
float scrollSpeed = 20;
float maxScroll = 0;
boolean creditsInitialized = false;

// New Login Variables
TextBox loginIDInput, passwordInput;
Button loginButton;
String enteredID = "", enteredPassword = "";
boolean loginFailed = false;

// === HOME PAGE ELEMENTS ===
Button aboutButton, simulationButton, liveDataButton, creditsButton, azimuthButton;
PFont titleFont, subtitleFont, buttonFont, HeadFont;

// === EXIT BUTTON ===
Button exitButton;
Button minButton;

// team update 
TeamMember[] teamMembers;

String[] monthNames = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
};
// === RADAR ANIMATION VARIABLES ===
float radarAngle = 0;
float elevationAngle = 20;
float elevationDirection = 1;
float radarSize = 120;
float radarX, radarY;

// === SERIAL COMMUNICATION ===
Serial arduino;
String arduinoPort = "";
boolean serialConnected = false;

// === SIMULATION PAGE VARIABLES ===
PVector radarCenter;
float radarRadius = 250;
ArrayList<RadarTarget> targets;
ArrayList<EchoPoint> echoPoints;
float currentElevation = 20.0;
float targetElevation = 20.0;
boolean isMoving = false;
boolean powerOn = true;
float beamWidth = 15;
ArrayList<BeamSweep> beamHistory;
int maxBeamHistory = 25;
float sweepAngle = 0;
boolean sweeping = true;
float elevationSmoothing = 0.08;
Button homeButton, stopButton, connectButton;
Button[] quickButtons;
Slider elevationSlider;
TextBox angleInput;
color radarGreen = color(0, 255, 120);
color radarAmber = color(255, 180, 0);
color radarRed = color(255, 60, 60);
color beamColor = color(0, 255, 120, 80);
color panelBg = color(25, 35, 45);
color textColor = color(220, 235, 250);
PImage img, img1, img2,img3;  
Frame frame;
boolean isMaximized = false;

// === AZIMUTH PAGE VARIABLES ===
float azimuthAngle = 0.0; // Current azimuth angle (0-360)
float azimuthSpeed = 0.0; // Current speed (-100 to 100)
float targetAzimuthSpeed = 0.0; // Target speed
float azimuthAcceleration = 0.2; // Speed change rate
ArrayList<Float> speedHistory; // Stores speed values for graph
ArrayList<Float> angleHistory; // Stores angle values for graph
int maxHistoryPoints = 200; // Max points to keep in history
Button azHomeButton, azStopButton, azConnectButton;
Button[] azSpeedButtons;
Slider azSpeedSlider;
Slider azAccelSlider;
Button azManualToggle;
boolean manualMode = true;
TextBox azSpeedInput;
float maxRPM = 30.0; // Max RPM for the motor
Graph speedGraph, positionGraph;

void setup() {
   size(1920, 1344);
  smooth();
  fullScreen();
  
  // Create login page inputs
  loginIDInput = new TextBox(width / 2 - 150, height / 2 - 60, 300, 40, "Enter ID");
  passwordInput = new TextBox(width / 2 - 150, height / 2, 300, 40, "Enter Password");
  loginButton = new Button(width / 2 - 150, height / 2 + 60, 300, 60, "LOGIN", primaryColor);
  
  // Create exit button
  exitButton = new Button(width - 60, 20, 40, 25, "x", color(180, 40, 40));
  minButton = new Button(width - 120, 20, 40, 25, "-", color(128,128,128));
  
  frame = (Frame) ((processing.awt.PSurfaceAWT.SmoothCanvas) surface.getNative()).getFrame();
  
  // Set radar position in top-right corner
  radarX = width - 200;
  radarY = 100;
  
  // Load fonts
  titleFont = createFont("Outfit-SemiBold.ttf", 36);
  subtitleFont = createFont("Montserrat-SemiBold.ttf", 18);
  buttonFont = createFont("Righteous-Regular.ttf", 16);
  
  // Create home page buttons
  aboutButton = new Button(width/2 - 150, height/2 - 105, 300, 60, "ABOUT", primaryColor);
  simulationButton = new Button(width/2 - 150, height/2 -10, 300, 60, "ELEVATION CONTROL", secondaryColor);
  azimuthButton = new Button(width/2 - 150, height/2 + 80, 300, 60, "AZIMUTH CONTROL", color(80, 180, 120));
  liveDataButton = new Button(width/2 - 150, height/2 + 170, 300, 60, "VIEW LIVE DATA", color(120));
  creditsButton = new Button(width/2 - 150, height/2 + 260, 300, 60, "CREDITS", primaryColor);

  // Initialize simulation
  initializeSimulation();
  
  // Initialize azimuth page
  initializeAzimuthPage();
  
  img = loadImage("radarpic3.png"); 
  img1 = loadImage("India_Meteorological_Department_(logo).png");
  img2 = loadImage("banner.png");
  img3 = loadImage("vishalpic.jpg");
  // In setup()
  teamMembers = new TeamMember[5];
  teamMembers[0] = new TeamMember("Vishal Meyyappan R", "GUI and Code Devolver\nElectronics and Circuit Designer", 
      "https://www.linkedin.com/in/vishalmeyyappanr", "vishalmeyyappan@gmail.com");
  teamMembers[1] = new TeamMember("Ashwin R", "GUI and Code Devolver\nElectronics and Circuit Designer", 
      "https://www.linkedin.com/in/ashwinr07/", "walkindice@gmail.com");
  teamMembers[2] = new TeamMember("Kishore V S", "GUI and Code Devolver\nElectronics and Circuit Designer", 
      "https://www.linkedin.com/in/kishore-vs-94708a271/", "kishorevs");
  teamMembers[3] = new TeamMember("Rayhan Hameed", "Documentation\nElectronics and Circuit Designer", 
      "https://www.linkedin.com/in/rayhanh5106/", "rayhanhameed5@gmail.com");

  teamMembers[4] = new TeamMember("Yuvan Shankar", "Documentation\nElectronics and Circuit Designer", 
      "https://www.linkedin.com/in/yuvan-shankar-a74369315/", "yuvanshankar086@gmail.com");
  
  // Load actual images if available
  loadMemberPhotos();
  // Start on login page
  currentPage = -1;
}

void draw() {
  background(bgColor);
  
  switch (currentPage) {
    case -1: // Login Page
      drawLoginPage();
      break;
    case 0: // Home Page
      drawHomePage();
      break;
    case 1: // About Page
      drawAboutPage();
      break;
    case 2: // Simulation Page
      drawSimulationPage();
      break;
    case 3: // Credits Page
      drawCreditsPage();
      break;
    case 4: // Azimuth Page
      drawAzimuthPage();
      break;
  }
  
  // Always display exit button on all pages
  exitButton.display();
  minButton.display();
}

void drawLoginPage() {
  // Background for login screen
  background(50, 50, 50);
  fill(lightText);
  textSize(36);
  textAlign(CENTER, CENTER);
  text("Doppler Weather Radar - Admin Login", width / 2, height / 3 - 100);

  // Draw error message if login failed
  if (loginFailed) {
    fill(255, 0, 0);
    textSize(24);
    text("Invalid ID or Password. Please try again.", width / 2, height / 3 + 150);
  }

  // Draw login input fields
  loginIDInput.display();
  passwordInput.display();
  loginButton.display();
}


void serialEvent(Serial p) {
  String incoming = p.readStringUntil('\n');
  if (incoming != null) {
    incoming = trim(incoming);

    if (incoming.equals("POWER:ON")) {
      powerOn = true;
    } else if (incoming.equals("POWER:OFF")) {
      powerOn = false;
    }
  }
}

// ======================
// HOME PAGE
// ======================
void drawHomePage() {
  // Draw background elements
  drawBackgroundPattern();
  image(img1, 240, 50, img.width/5, img.height/4);
  image(img2, 990, 30, img.width/1.2, img.height/2.7);

  // Get current date and time
  int currentDay = day();
  int currentMonth = month();
  int currentYear = year();
  String monthName = monthNames[currentMonth - 1];
  String formattedDate = monthName + " " + currentDay + ", " + currentYear;
  String formattedTime = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);

  // Draw Date and Time with glow effect
  pushMatrix();
  translate(width - 120, 90);
  // Outer glow
  for (int i = 0; i < 3; i++) {
    fill(accentColor, 30 - i * 10);
    textSize(18 + i * 2);
    textAlign(RIGHT);
    text(formattedDate, 0, 0);
    text(formattedTime, 0, 20);
  }
  // Inner text
  fill(accentColor);
  textFont(titleFont);
  textSize(18);
  text(formattedDate, 0, 0);
  textFont(subtitleFont);
  textSize(16);
  text(formattedTime, 0, 20);
  popMatrix();
  text("Chennai, Tamil Nadu, India",width/2 + 700, 140);
  // Draw title with shadow
  fill(0, 80);
  textAlign(CENTER, CENTER);
  textFont(titleFont);
  text("Doppler Weather Radar Control Panel", width/2 + 2, 102);
  fill(primaryColor);
  text("Doppler Weather Radar Control Panel", width/2, 100);

  // Draw subtitle
  fill(darkText);
  textFont(subtitleFont);
  text("By Chennai Institute of Technology Students - IMD Project", width/2, 150);

  // Draw buttons
  aboutButton.display();
  simulationButton.display();
  liveDataButton.display();
  creditsButton.display();
  azimuthButton.display();
}

// Draw Time and Date in a stylish way
void drawTimeDate() {
  PFont timeFont = createFont("Montserrat-SemiBold.ttf", 24); // Using a clean, modern font
  
  // Get the current time and date using Processing's built-in functions
  int hour = hour();  // Current hour
  int minute = minute();  // Current minute
  int second = second();  // Current second
  int day = day();  // Current day
  int month = month();  // Current month
  int year = year();  // Current year
  
  String timeString = nf(hour, 2, 0) + ":" + nf(minute, 2, 0) + ":" + nf(second, 2, 0);
  String dateString = nf(day, 2, 0) + "/" + nf(month, 2, 0) + "/" + year;
  
  // Time display style (gradient background for a sleek look)
  fill(239, 255, 255, 220);
  noStroke();
  rect(width - 270, 30, 220, 60, 10);
  
  // Gradient effect for time background
  for (int i = 0; i < 10; i++) {
    float inter = map(i, 0, 10, 0, 1);
    color c1 = lerpColor(color(0, 82, 147), color(0, 120, 215), inter);
    fill(c1);
    rect(width - 270, 30 + i * 6, 220, 6);
  }
  
  // Draw the time in a large, stylish format
  fill(255);
  textFont(timeFont);
  textAlign(CENTER, CENTER);
  text(timeString, width - 160, 40);
  
  // Draw the date below the time in a smaller size
  textFont(subtitleFont);
  textSize(16);
  text(dateString, width - 160, 65);
}


void drawBackgroundPattern() {
  noStroke();
  for (int i = 0; i < width; i += 40) {
    for (int j = 0; j < height; j += 40) {
      fill(230, 235, 240);
      ellipse(i, j, 3, 3);
    }
  }
  
  // Draw wave pattern at bottom
  fill(primaryColor, 30);
  beginShape();
  for (int x = 0; x <= width; x += 10) {
    float y = height - 50 + sin(radians(x * 2 + frameCount * 2)) * 15;
    vertex(x, y);
  }
  vertex(width, height);
  vertex(0, height);
  endShape(CLOSE);
}

// ======================
// ABOUT PAGE
// ======================
void drawAboutPage() {
  // Draw header
  drawPageHeader("About the Project");
  
  // Draw content
  fill(darkText);
  textFont(subtitleFont);
  textAlign(LEFT);
  
  String aboutText = "This Doppler Weather Radar simulation is an educational project developed\n" +
                    "by students of Chennai Institute of Technology under the guidance of\n" +
                    "India Meteorological Department (IMD).\n\n" +
                    "The system demonstrates the principles of weather radar technology\n" +
                    "using Arduino microcontrollers to control servo motors that adjust\n" +
                    "the radar's elevation and azimuth angles.\n\n" +
                    "Key components:\n" +
                    "• Arduino Uno controller\n" +
                    "• Two servo motors for positioning\n" +
                    "• Two potentiometers for manual control\n" +
                    "• Custom Processing visualization software\n\n" +
                    "The simulation shows how weather radars detect precipitation and\n" +
                    "measure its intensity, movement, and elevation characteristics.";
  
  text(aboutText, 100, 180);
  image(img, 900, height/2-140, img.width/2, img.height/2);
}
void drawPageHeader(String title) {
  fill(primaryColor);
  noStroke();
  rect(0, 0, width, 60);
  
  fill(lightText);
  textFont(titleFont, 24);
  textAlign(CENTER, CENTER);
  text(title, width/2, 30);
  
  // Back button
  fill(lightText);
  textFont(buttonFont, 16);
  textAlign(LEFT, CENTER);
  text("< Back", 20, 30);
}


void initializeSerial() {
  try {
    String[] ports = Serial.list();
    for (String port : ports) {
      if (port.contains("COM") || port.contains("tty.usb") || port.contains("ACM")) {
        arduinoPort = port;
        break;
      }
    }
    
    if (!arduinoPort.equals("") && ports.length > 0) {
      arduino = new Serial(this, arduinoPort, 9600);
      serialConnected = true;
      sendElevationCommand(20.0);
    }
  } catch (Exception e) {
    serialConnected = false;
  }
}



void sendElevationCommand(float angle) {
  if (serialConnected && arduino != null) {
    try {
      String command = "E" + nf(angle, 0, 1);
      arduino.write(command);
    } catch (Exception e) {
      serialConnected = false;
    }
  }
}

void updateElevation() {
  if (abs(targetElevation - currentElevation) > 0.1) {
    isMoving = true;
    currentElevation = lerp(currentElevation, targetElevation, elevationSmoothing);
  } else {
    isMoving = false;
    currentElevation = targetElevation;
  }
  
  if (frameCount % 3 == 0) {
    beamHistory.add(new BeamSweep(currentElevation));
    if (beamHistory.size() > maxBeamHistory) {
      beamHistory.remove(0);
    }
  }
}

void updateRadarSweep() {
  if (sweeping) {
    sweepAngle += 1;
    if (sweepAngle >= 360) sweepAngle = 0;
  }
}


void updateTargetVisibility() {
  for (RadarTarget target : targets) {
    float beamLow = currentElevation - beamWidth/2;
    float beamHigh = currentElevation + beamWidth/2;
    
    target.isVisible = (target.elevation >= beamLow && target.elevation <= beamHigh);
    
    if (target.isVisible && random(100) < 2) {
      float targetX = cos(radians(target.elevation)) * target.distance;
      float targetY = -sin(radians(target.elevation)) * target.distance;
      echoPoints.add(new EchoPoint(targetX, targetY, target.intensity));
    }
  }
}


void drawRadarDisplay() {
  pushMatrix();
  translate(radarCenter.x, radarCenter.y);
  
  // Draw range rings
  stroke(radarGreen, 60);
  strokeWeight(1);
  noFill();
  for (int i = 1; i <= 5; i++) {
    arc(0, 0, (radarRadius * i) / 2.5, (radarRadius * i) / 2.5, PI, TWO_PI);
  }
  
  // Range labels
  fill(textColor, 150);
  textAlign(CENTER);
  textSize(10);
  for (int i = 1; i <= 5; i++) {
    float ringRadius = (radarRadius * i) / 5;
    text(str(i * 20) + "km", 0, -ringRadius + 5);
  }
  
  // Draw elevation grid lines
  stroke(radarGreen, 40);
  strokeWeight(1);
  for (int angle = 0; angle <= 90; angle += 15) {
    float x = cos(radians(angle)) * radarRadius;
    float y = -sin(radians(angle)) * radarRadius;
    line(0, 0, x, y);
    
    // Elevation angle labels
    if (angle > 0) {
      fill(textColor, 120);
      textAlign(LEFT);
      textSize(9);
      text(angle + "°", x + 5, y - 5);
    }
  }
  
  // Draw beam history
  for (int i = 0; i < beamHistory.size(); i++) {
    BeamSweep beam = beamHistory.get(i);
    float alpha = map(i, 0, beamHistory.size() - 1, 10, 60);
    
    fill(beamColor, alpha);
    noStroke();
    beginShape();
    vertex(0, 0);
    for (float a = beam.elevation - beamWidth/2; a <= beam.elevation + beamWidth/2; a += 2) {
      float x = cos(radians(a)) * radarRadius;
      float y = -sin(radians(a)) * radarRadius;
      vertex(x, y);
    }
    endShape(CLOSE);
  }
  
  // Current elevation beam
  fill(beamColor, 120);
  noStroke();
  beginShape();
  vertex(0, 0);
  for (float a = currentElevation - beamWidth/2; a <= currentElevation + beamWidth/2; a += 1) {
    float x = cos(radians(a)) * radarRadius;
    float y = -sin(radians(a)) * radarRadius;
    vertex(x, y);
  }
  endShape(CLOSE);
  
  // Draw main elevation line
  stroke(radarGreen, 200);
  strokeWeight(3);
  float mainX = cos(radians(currentElevation)) * radarRadius;
  float mainY = -sin(radians(currentElevation)) * radarRadius;
  line(0, 0, mainX, mainY);
  
  // Elevation angle indicator
  fill(radarAmber);
  noStroke();
  circle(mainX, mainY, 8);
  
  // Draw radar targets
  for (RadarTarget target : targets) {
    if (target.isVisible) {
      target.display();
    }
  }
  
  popMatrix();
  
  // Draw ground line
  stroke(radarGreen, 100);
  strokeWeight(2);
  line(50, radarCenter.y, width - 50, radarCenter.y);
  
  fill(textColor, 120);
  textAlign(LEFT);
  textSize(12);
  text("GROUND LEVEL", 60, radarCenter.y + 20);
}

void drawElevationBeam() {
  // Side view elevation display
  float sideX = 50;
  float sideY = 100;
  float sideWidth = 200;
  float sideHeight = 150;
  
  // Panel background
  fill(panelBg);
  stroke(radarGreen, 100);
  strokeWeight(1);
  rect(sideX, sideY, sideWidth, sideHeight);
  
  // Title
  fill(textColor);
  textAlign(LEFT);
  textSize(14);
  text("ELEVATION PROFILE", sideX + 10, sideY + 20);
  
  // Draw elevation arc
  pushMatrix();
  translate(sideX + 20, sideY + sideHeight - 20);
  
  // Draw elevation angles
  stroke(radarGreen, 80);
  strokeWeight(1);
  noFill();
  for (int angle = 0; angle <= 90; angle += 15) {
    float arcRadius = 80;
    float x = cos(radians(angle)) * arcRadius;
    float y = -sin(radians(angle)) * arcRadius;
    line(0, 0, x, y);
  }
  
  // Current elevation beam
  stroke(radarAmber);
  strokeWeight(4);
  float beamRadius = 80;
  float beamX = cos(radians(currentElevation)) * beamRadius;
  float beamY = -sin(radians(currentElevation)) * beamRadius;
  line(0, 0, beamX, beamY);
  
  // Beam cone
  fill(beamColor, 100);
  noStroke();
  beginShape();
  vertex(0, 0);
  for (float a = currentElevation - beamWidth/2; a <= currentElevation + beamWidth/2; a += 2) {
    float x = cos(radians(a)) * beamRadius;
    float y = -sin(radians(a)) * beamRadius;
    vertex(x, y);
  }
  endShape(CLOSE);
  
  popMatrix();
}

void drawStatusBar() {
  // Bottom status bar
  fill(panelBg);
  stroke(radarGreen, 80);
  strokeWeight(1);
  rect(0, height - 40, width, 40);
  
  fill(textColor);
  textAlign(LEFT);
  textSize(12);
  String connectionStatus = serialConnected ? "CONNECTED" : "DISCONNECTED";
  text("ELEVATION RADAR | Arduino: " + connectionStatus + " | Beam: Active | Sweep: " + (sweeping ? "ON" : "OFF"), 20, height - 20);
  
  // Real-time angle display
  textAlign(RIGHT);
  textSize(14);
  fill(radarAmber);
  text("ELEVATION: " + nf(currentElevation, 0, 1) + "°", width - 20, height - 15);
}

void drawControls() {
  // Draw all GUI elements
  homeButton.display();
  stopButton.display();
  connectButton.display();
  
  for (Button btn : quickButtons) {
    btn.display();
  }
  
  elevationSlider.display();
  angleInput.display();
  
  // Instructions
  fill(textColor, 180);
  textAlign(LEFT);
  textSize(10);
  text("Enter angle and press ENTER:", width - 270, 240);
}



// ======================
// CREDITS PAGE
// ======================
void drawCreditsPage() {
  // Initialize positions on first visit
  if (!creditsInitialized) {
    arrangeTeamMembers();
    creditsInitialized = true;
  }
  
  // Draw fixed header
  drawPageHeader("Project Credits");
  
  // Update max scroll
  float contentHeight = 300 + ceil(teamMembers.length / 3.0) * 400;
  maxScroll = max(0, contentHeight - (height - 200));
  
  // Apply scroll offset
  pushMatrix();
  translate(0, -creditsScrollY);
  
  // Supervisor info
  fill(lightText);
  textFont(subtitleFont);
  textAlign(CENTER);
  text("Project Supervisor:\nMr. Arul Malar Kannan. B , IMS Scientist F & Head \n and \n Mr. A. Elangovan, Meteorologist DWR \n\n", width/2, 150);
  
  // Team section header
  fill(accentColor);
  textSize(24);
  text("Development Team", width/2, 230);
  
  // Update positions and animations
  for (TeamMember member : teamMembers) {
    member.updateAnimation();
    member.checkHover(creditsScrollY);
    member.display();
  }
  
  // Institution info
  float contentBottom = 300 + ceil(teamMembers.length / 3.0) * 400;
  fill(lightText);
  textSize(18);
  text("\n\nInstitution Name:\n Chennai Institute Of Technology ", width/2, contentBottom + 50); 
  text("\n\nAffiliated Organisation:\n RMC Chennai, IMD, MoES", width/2, contentBottom + 120);
  
  text("Special Thanks to:\nDoppler Weather Radar(IMD), Chennai\nfor their support and guidance", width/2, contentBottom + 200);
  
  popMatrix();
  
  // Draw scroll indicator
  if (maxScroll > 0) {
    float scrollPos = map(creditsScrollY, 0, maxScroll, 0, height - 100);
    fill(200, 200);
    rect(width - 20, 100, 10, height - 200, 5);
    fill(accentColor);
    rect(width - 20, 100 + scrollPos, 10, 80, 5);
  }
}

void arrangeTeamMembers() {
  float startX = 150;
  float startY = 300;
  float cardWidth = 280;
  float cardHeight = 360;
  float marginX = (width - 3 * cardWidth) / 4;
  float marginY = 40;
  
  for (int i = 0; i < teamMembers.length; i++) {
    int row = i / 3;
    int col = i % 3;
    teamMembers[i].x = startX + col * (cardWidth + marginX);
    teamMembers[i].y = startY + row * (cardHeight + marginY);
    teamMembers[i].targetY = teamMembers[i].y;
  }
}

void mouseWheel(MouseEvent event) {
  if (currentPage == 3) { // Credits Page
    float scrollAmount = event.getCount() * scrollSpeed;
    creditsScrollY = constrain(creditsScrollY + scrollAmount, 0, maxScroll);
  }
}

// ======================
// SIMULATION PAGE
// ======================
void initializeSimulation() {
  radarCenter = new PVector(width/2, height - 120);
  targets = new ArrayList<RadarTarget>();
  echoPoints = new ArrayList<EchoPoint>();
  beamHistory = new ArrayList<BeamSweep>();
  
  // Create buttons
  homeButton = new Button(width - 270, 330, 60, 35, "HOME", color(80));
  stopButton = new Button(width - 200, 330, 60, 35, "STOP", color(180, 40, 40));
  connectButton = new Button(width - 130, 330, 60, 35, "RC", color(60, 140, 200));
  
  // Quick angle buttons
  quickButtons = new Button[4];
  quickButtons[0] = new Button(width - 270, 290, 35, 25, "0°", color(100));
  quickButtons[1] = new Button(width - 230, 290, 35, 25, "30°", color(100));
  quickButtons[2] = new Button(width - 190, 290, 35, 25, "60°", color(100));
  quickButtons[3] = new Button(width - 150, 290, 35, 25, "90°", color(100));
  
  // Slider for elevation
  elevationSlider = new Slider(50, 350, 300, 20, 0, 90, 20);
  
  // Text input
  angleInput = new TextBox(width - 270, 250, 100, 25, "20.0");
  
  // Generate sample targets
  for (int i = 0; i < 20; i++) {
    float elevation = random(0, 90);
    float distance = random(30, radarRadius - 20);
    float intensity = random(0.3, 1.0);
    targets.add(new RadarTarget(elevation, distance, intensity));
  }
  
  // Initialize serial communication
  initializeSerial();
}

void drawSimulationPage() {
  background(8, 15, 25);
  
  // Update system - THIS WAS MISSING IN YOUR UPDATED CODE
  updateElevation();
  updateRadarSweep();
  updateTargetVisibility();
  
  // Draw components
  drawRadarDisplay();
  drawElevationBeam();
  drawControlPanel();
  drawStatusBar();
  
  // Draw GUI controls
  drawControls();
  
  // Draw page header
  drawPageHeader("Radar Elevation Control");
}


// ... [Rest of simulation page code remains the same] ...

// ======================
// AZIMUTH PAGE
// ======================
void initializeAzimuthPage() {
  // Initialize data history
  speedHistory = new ArrayList<Float>(Collections.nCopies(maxHistoryPoints, 0.0f));
  angleHistory = new ArrayList<Float>(Collections.nCopies(maxHistoryPoints, 0.0f));
  
  // Create buttons
  azHomeButton = new Button(width - 270, 330, 60, 35, "HOME", color(80, 180, 120));
  azStopButton = new Button(width - 200, 330, 60, 35, "STOP", color(180, 40, 40));
  azConnectButton = new Button(width - 130, 330, 60, 35, "RC", color(60, 140, 200));
  azManualToggle = new Button(width - 270, 250, 120, 35, "MANUAL MODE", color(100, 150, 200));
  
  // Quick speed buttons
  azSpeedButtons = new Button[5];
  azSpeedButtons[0] = new Button(width - 270, 290, 45, 25, "-100%", color(100));
  azSpeedButtons[1] = new Button(width - 220, 290, 45, 25, "-50%", color(100));
  azSpeedButtons[2] = new Button(width - 170, 290, 45, 25, "0%", color(100));
  azSpeedButtons[3] = new Button(width - 120, 290, 45, 25, "50%", color(100));
  azSpeedButtons[4] = new Button(width - 70, 290, 45, 25, "100%", color(100));
  
  // Sliders
  azSpeedSlider = new Slider(50, 150, 300, 20, -100, 100, 0);
  azAccelSlider = new Slider(50, 250, 300, 20, 0.1, 1.0, 0.2);
  
  // Text input
  azSpeedInput = new TextBox(width - 270, 210, 100, 25, "0.0");
  
  // Create graphs
  speedGraph = new Graph(50, 350, 400, 200, "SPEED (RPM)", -maxRPM, maxRPM, color(0, 200, 255));
  positionGraph = new Graph(50, 580, 400, 200, "POSITION (°)", 0, 360, color(255, 180, 0));
}


// Add this after setup() to load real images
void loadMemberPhotos() {
  teamMembers[0].photo = loadImage("vishalpic.jpg");
  teamMembers[1].photo = loadImage("ashwinpic.png");
  teamMembers[2].photo = loadImage("kicha.jpg");
  teamMembers[3].photo = loadImage("RAYHAN.jpg");
  teamMembers[4].photo = loadImage("Yuvan.jpg");
  
  // Resize images if needed
  for (TeamMember member : teamMembers) {
    if (member.photo != null) {
      member.photo.resize(150, 150);
    }
  }
}



void drawAzimuthPage() {
  background(8, 15, 25);
  
  // Update azimuth system
  updateAzimuth();
  
  // Draw components
  drawAzimuthDisplay();
  drawControlPanel();
  drawStatusBar();
  drawGraphs();
  
  // Draw GUI controls
  drawAzimuthControls();
  
  // Draw page header
  drawPageHeader("Azimuth Motor Control");
}

void updateAzimuth() {
  // Smoothly adjust speed toward target
  if (abs(azimuthSpeed - targetAzimuthSpeed) > azimuthAcceleration) {
    if (azimuthSpeed < targetAzimuthSpeed) {
      azimuthSpeed += azimuthAcceleration;
    } else {
      azimuthSpeed -= azimuthAcceleration;
    }
  } else {
    azimuthSpeed = targetAzimuthSpeed;
  }
  
  // Update azimuth angle based on speed
  azimuthAngle += (azimuthSpeed * maxRPM) / 600.0; // 600 is an arbitrary scaling factor
  azimuthAngle %= 360;
  if (azimuthAngle < 0) azimuthAngle += 360;
  
  // Update history
  updateHistory();
}

void updateHistory() {
  // Shift existing data
  for (int i = 0; i < maxHistoryPoints - 1; i++) {
    speedHistory.set(i, speedHistory.get(i + 1));
    angleHistory.set(i, angleHistory.get(i + 1));
  }
  
  // Add new data
  speedHistory.set(maxHistoryPoints - 1, (azimuthSpeed * maxRPM) / 100.0);
  angleHistory.set(maxHistoryPoints - 1, azimuthAngle);
}

void drawAzimuthDisplay() {
  pushMatrix();
  translate(width/2, height/2 - 100);
  
  // Draw azimuth ring
  noFill();
  stroke(radarGreen, 100);
  strokeWeight(2);
  ellipse(0, 0, 400, 400);
  
  // Draw degree markers
  fill(textColor);
  textSize(12);
  textAlign(CENTER, CENTER);
  for (int i = 0; i < 360; i += 30) {
    float x = cos(radians(i)) * 190;
    float y = sin(radians(i)) * 190;
    text(str(i) + "°", x, y);
  }
  
  // Draw direction indicator
  stroke(radarAmber);
  strokeWeight(3);
  float indicatorX = cos(radians(azimuthAngle)) * 180;
  float indicatorY = sin(radians(azimuthAngle)) * 180;
  line(0, 0, indicatorX, indicatorY);
  
  // Draw arrowhead
  fill(radarAmber);
  noStroke();
  pushMatrix();
  translate(indicatorX, indicatorY);
  rotate(radians(azimuthAngle));
  triangle(0, -10, 20, 0, 0, 10);
  popMatrix();
  
  // Draw speed indicator
  fill(radarGreen);
  textSize(24);
  textAlign(CENTER);
  text(nf(azimuthSpeed, 0, 1) + "%", 0, 0);
  
  // Draw direction text
  textSize(16);
  if (azimuthSpeed > 0) {
    text("CLOCKWISE", 0, 40);
  } else if (azimuthSpeed < 0) {
    text("COUNTER-CLOCKWISE", 0, 40);
  } else {
    text("STOPPED", 0, 40);
  }
  
  // Draw RPM
  textSize(14);
  text("RPM: " + nf(abs(azimuthSpeed * maxRPM / 100.0), 0, 1), 0, 70);
  
  popMatrix();
}

void drawControlPanel() {
  // Main control panel
  fill(panelBg);
  stroke(radarGreen, 100);
  strokeWeight(1);
  rect(width - 280, 50, 260, 350);
  
  // Title
  fill(textColor);
  textAlign(LEFT);
  textSize(16);
  text("AZIMUTH CONTROL", width - 270, 75);
  
  // Current readings
  textSize(12);
  text("Angle: " + nf(azimuthAngle, 0, 1) + "°", width - 270, 100);
  text("Speed: " + nf(azimuthSpeed, 0, 1) + "%", width - 270, 120);
  text("RPM: " + nf(abs(azimuthSpeed * maxRPM / 100.0), 0, 1), width - 270, 140);
  
  // Connection status
  fill(serialConnected ? radarGreen : radarRed);
  noStroke();
  circle(width - 100, 155, 8);
  fill(textColor);
  textSize(10);
  text(serialConnected ? "CONNECTED" : "DISCONNECTED", width - 140, 160);
  
  // Power indicator
  if(powerOn){
    fill(radarGreen);
  }
  else{
    fill(radarRed);
  }
  noStroke();
  circle(width - 100, 95, 12);
  fill(textColor);
  textSize(12);
  text("PWR", width - 120, 100);
  
  // Mode indicator
  fill(manualMode ? radarAmber : radarGreen);
  noStroke();
  circle(width - 100, 115, 8);
  fill(textColor);
  textSize(10);
  text(manualMode ? "MANUAL" : "AUTO", width - 140, 120);
  
  // Acceleration setting
  text("Acceleration: " + nf(azimuthAcceleration, 0, 2), width - 270, 180);
}

void drawGraphs() {
  speedGraph.display();
  positionGraph.display();
  
  // Draw speed graph data
  speedGraph.drawData(speedHistory);
  
  // Draw position graph data
  positionGraph.drawData(angleHistory);
}

void drawAzimuthControls() {
  // Draw all GUI elements
  azHomeButton.display();
  azStopButton.display();
  azConnectButton.display();
  azManualToggle.display();
  
  for (Button btn : azSpeedButtons) {
    btn.display();
  }
  
  azSpeedSlider.display();
  azAccelSlider.display();
  azSpeedInput.display();
  
  // Labels
  fill(textColor);
  textAlign(LEFT);
  textSize(12);
  text("Speed Control (%):", 50, 130);
  text("Acceleration Rate:", 50, 230);
  text("Set Speed (%):", width - 270, 200);
}

void setAzimuthSpeed(float speed) {
  targetAzimuthSpeed = constrain(speed, -100, 100);
  azSpeedSlider.value = targetAzimuthSpeed;
  sendAzimuthCommand(targetAzimuthSpeed);
}

void sendAzimuthCommand(float speed) {
  if (serialConnected && arduino != null) {
    try {
      String command = "C" + nf(speed, 0, 1);
      arduino.write(command);
    } catch (Exception e) {
      serialConnected = false;
    }
  }
}

// ======================
// GRAPH CLASS
// ======================
class Graph {
  float x, y, w, h;
  String title;
  float minVal, maxVal;
  color graphColor;
  
  Graph(float px, float py, float pw, float ph, String t, float min, float max, color c) {
    x = px; y = py; w = pw; h = ph;
    title = t;
    minVal = min;
    maxVal = max;
    graphColor = c;
  }
  
  void display() {
    // Background
    fill(panelBg);
    stroke(radarGreen, 100);
    strokeWeight(1);
    rect(x, y, w, h);
    
    // Title
    fill(textColor);
    textAlign(CENTER);
    textSize(14);
    text(title, x + w/2, y - 10);
    
    // Grid lines
    stroke(radarGreen, 50);
    strokeWeight(1);
    
    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      float yPos = y + h - i * (h / 4);
      line(x, yPos, x + w, yPos);
      
      // Labels
      float val = map(i, 0, 4, minVal, maxVal);
      textAlign(RIGHT);
      textSize(10);
      text(nf(val, 0, 1), x - 5, yPos + 5);
    }
    
    // Vertical lines (time markers)
    for (int i = 0; i <= 4; i++) {
      float xPos = x + i * (w / 4);
      line(xPos, y, xPos, y + h);
    }
    
    // Zero line if applicable
    if (minVal < 0 && maxVal > 0) {
      stroke(radarAmber, 100);
      float zeroY = map(0, minVal, maxVal, y + h, y);
      line(x, zeroY, x + w, zeroY);
    }
  }
  
  void drawData(ArrayList<Float> data) {
    if (data.size() < 2) return;
    
    noFill();
    stroke(graphColor);
    strokeWeight(2);
    beginShape();
    
    for (int i = 0; i < data.size(); i++) {
      float val = constrain(data.get(i), minVal, maxVal);
      float xPos = map(i, 0, data.size() - 1, x, x + w);
      float yPos = map(val, minVal, maxVal, y + h, y);
      vertex(xPos, yPos);
    }
    
    endShape();
  }
}

// ======================
// EVENT HANDLERS
// ======================
void mousePressed() {
  // Check if clicked on login ID input
  if (loginIDInput.isClicked(mouseX, mouseY)) {
    loginIDInput.activate(); // Activate and clear placeholder text
    passwordInput.deactivate(); // Deactivate password input field and restore placeholder text
  }
  // Check if clicked on password input
  else if (passwordInput.isClicked(mouseX, mouseY)) {
    passwordInput.activate(); // Activate and clear placeholder text
    loginIDInput.deactivate(); // Deactivate login ID input field and restore placeholder text
  }
  
  // Check for exit button
  if (exitButton.isClicked(mouseX, mouseY)) {
    exit();
  }
  // Minimize button
  else if(minButton.isClicked(mouseX, mouseY)) {
    frame.setState(Frame.ICONIFIED);
  }

  // Handle login button click
  if (currentPage == -1 && loginButton.isClicked(mouseX, mouseY)) {
    handleLogin();
  }

  // Check other pages
  else if (currentPage == 0) { // Home Page
    if (aboutButton.isClicked(mouseX, mouseY)) {
      currentPage = 1;
    } else if (simulationButton.isClicked(mouseX, mouseY)) {
      currentPage = 2;
    } else if (azimuthButton.isClicked(mouseX, mouseY)) {
      currentPage = 4;
    } else if (creditsButton.isClicked(mouseX, mouseY)) {
      currentPage = 3;
    }
  } 

  else if (currentPage == 1 || currentPage == 3) { // About or Credits Page
    // Back button
    if (mouseX < 100 && mouseY < 60) {
      currentPage = 0;
    }
  }

  else if (currentPage == 2) { // Simulation Page
    if (mouseX < 100 && mouseY < 60) {
      currentPage = 0;
    }

    // ADDED SIMULATION PAGE CONTROLS
    if (homeButton.isClicked(mouseX, mouseY)) {
      setTargetElevation(20);
    } else if (stopButton.isClicked(mouseX, mouseY)) {
      targetElevation = currentElevation;
      isMoving = false;
      if (serialConnected) sendElevationCommand(currentElevation);
    } else if (connectButton.isClicked(mouseX, mouseY)) {
      initializeSerial();
    }

    // Check quick buttons
    for (int i = 0; i < quickButtons.length; i++) {
      if (quickButtons[i].isClicked(mouseX, mouseY)) {
        float[] angles = {0, 30, 60, 90};
        setTargetElevation(angles[i]);
      }
    }

    // Check slider
    if (elevationSlider.isClicked(mouseX, mouseY)) {
      elevationSlider.isDragging = true;
    }

    // Check text box
    if (angleInput.isClicked(mouseX, mouseY)) {
      angleInput.isActive = true;
    } else {
      angleInput.isActive = false;
    }
  }

  else if (currentPage == 4) { // Azimuth Page
    // Back button
    if (mouseX < 100 && mouseY < 60) {
      currentPage = 0;
    }

    // Check button clicks
    if (azHomeButton.isClicked(mouseX, mouseY)) {
      setAzimuthSpeed(0);
      azimuthAngle = 0;
    } else if (azStopButton.isClicked(mouseX, mouseY)) {
      setAzimuthSpeed(0);
    } else if (azConnectButton.isClicked(mouseX, mouseY)) {
      initializeSerial();
    } else if (azManualToggle.isClicked(mouseX, mouseY)) {
      manualMode = !manualMode;
      azManualToggle.label = manualMode ? "MANUAL MODE" : "AUTO MODE";
    }

    // Check quick buttons
    for (int i = 0; i < azSpeedButtons.length; i++) {
      if (azSpeedButtons[i].isClicked(mouseX, mouseY)) {
        float[] speeds = {-100, -50, 0, 50, 100};
        setAzimuthSpeed(speeds[i]);
      }
    }

    // Check sliders
    if (azSpeedSlider.isClicked(mouseX, mouseY)) {
      azSpeedSlider.isDragging = true;
    }
    if (azAccelSlider.isClicked(mouseX, mouseY)) {
      azAccelSlider.isDragging = true;
    }

    // Check text box
    if (azSpeedInput.isClicked(mouseX, mouseY)) {
      azSpeedInput.isActive = true;
    } else {
      azSpeedInput.isActive = false;
    }
  }
  if (currentPage == 3) { // Credits Page
    for (TeamMember member : teamMembers) {
      member.handleClick();
    }
    
    // Reset scroll when clicking on header
    if (mouseX < 100 && mouseY < 60) {
      creditsScrollY = 0;
    }
  }
}


void handleLogin() {
  // Get entered ID and password
  enteredID = loginIDInput.text;
  enteredPassword = passwordInput.text;
  
  // Check if credentials are correct
  if (enteredID.equals("VYARK") && enteredPassword.equals("VYARK")) {
    currentPage = 0;  // Redirect to Home page after successful login
  } else {
    loginFailed = true;  // Show error message if login fails
  }
}

void mouseReleased() {
  if (currentPage == 4) {
    azSpeedSlider.isDragging = false;
    azAccelSlider.isDragging = false;
  }
}

void mouseDragged() {
  if (currentPage == 2) {  // ADDED SIMULATION PAGE SLIDER DRAGGING
    if (elevationSlider.isDragging) {
      elevationSlider.update(mouseX);
      setTargetElevation(elevationSlider.value);
    }
  }

  else if (currentPage == 4) {
    if (azSpeedSlider.isDragging) {
      azSpeedSlider.update(mouseX);
      setAzimuthSpeed(azSpeedSlider.value);
    }
    if (azAccelSlider.isDragging) {
      azAccelSlider.update(mouseX);
      azimuthAcceleration = azAccelSlider.value;
    }
  }
}

void setTargetElevation(float angle) {
  targetElevation = constrain(angle, 0, 90);
  elevationSlider.value = targetElevation;
  sendElevationCommand(targetElevation);
}


// REMAINDING CODES ARE PRIVATE, Contact vishalmeyyappan@gmail.com for remainding codes
// cc ALL rights are reserved by Vishal Meyyappan R and his team.
