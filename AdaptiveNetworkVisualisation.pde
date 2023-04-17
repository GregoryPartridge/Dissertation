import processing.opengl.*;
import java.util.*;

String FILE_NAME = "edges";

Table table;
int num_links = 0;
int num_nodes = 1;
int num_nodes1 = 1;
PFont font;

String mode = "Basic";
String filtrationTechnique = "MinEdges";

float offset = 0;
float uiOffset = 0;
float sliderWidth = 50;
float olduiOffset = 0;
float originalPos = 0;

boolean sliderSelected = false;
boolean clicked = false;
float pointSize = 20;

boolean[] sliders = new boolean[5];
float[] sliderOffset = new float[5];
int[] currentValue = new int[5];

int[] edgesPerNode;

boolean[] nodes1;
boolean[] highlightEdges;
int[] nodeInClique;

float leftBorder;
float rightBorder;
float topBorder;
float bottomBorder;

int currentMinEdges = 0;
int currentKCores = 0;

int maxKCore;
int maxMinEdges;
int maxCliqueSize;
boolean[] KCore;
boolean[] minEdges;

int totalCliques;
int[] cliqueIndex;
int[] edgesPerClique;

boolean[][] adjacencyMatrix, matrixHighlight;

Float[] a, b;

int lastHolder = -1;

String graphType = "Network";
boolean abstraction = false;

Vec3d[] node_forces;

float matrixSize;

ArrayList<Table>[][] allCliques;

int[][] allEdges;

int cliqueSet = 0;

float scroll = -50;

class Vec3d
{
  float x, y, z;
  Vec3d()
  {
    x = 0;
    y = 0;
    z = 0;
  }
  Vec3d( float xx, float yy, float zz)
  {
    x = xx;
    y = yy;
    z = zz;
  }
};


class Particle
{
  float mass;
  Vec3d p;
  Vec3d v;
  Vec3d f;

  Particle()
  {
    mass = 1;
    p = new Vec3d();
    v = new Vec3d();
    f = new Vec3d();
  }

  void draw(int n)
  {
    if (highlightEdges[n-1])
    {
      fill(200, 150, 100);
    } else fill(0);
    if ((sqrt(((mouseX - width/2)-p.x)*((mouseX - width/2)-p.x) + ((mouseY - height/2)-p.y)*((mouseY - height/2)-p.y)) < pointSize))
    {
      fill(200, 100, 100);
      if (clicked && n!=0 && mode == "Filter")
      {
        nodes1[n-1] = false;
        findMaxKCore(table);
        KCore = findKCores(table, 0);
        minEdges = findMinEdges(table, 0);
        findMinEdges(table, 0);
        findMaxKCore(table);
      }
      if (clicked && n!=0 && mode == "Highlight")
      {
        highlightEdges[n-1] = true;
      }
    } else if (!highlightEdges[n-1]) fill(0);
    pushMatrix();
    //translate(p.x, p.y, p.z);
    translate(p.x, p.y);
    textSize(15);
    text(n, 10, 10);
    //fill(0);
    ellipse(0, 0, pointSize, pointSize);
    popMatrix();
  }

  void drawClique(int n)
  {
    if ((sqrt(((mouseX - width/2)-p.x)*((mouseX - width/2)-p.x) + ((mouseY - height/2)-p.y)*((mouseY - height/2)-p.y)) < pointSize))
    {
      fill(200, 100, 100);
      if ((clicked && n!=0 && mode == "Filter"))
      {
        nodes1[n-1] = false;
        findMaxKCore(table);
        KCore = findKCores(table, 0);
        minEdges = findMinEdges(table, 0);
        findMinEdges(table, 0);
        findMaxKCore(table);
      }
      if (clicked && n!=0 && mode == "Highlight")
      {
        if (highlightEdges[n-2])  highlightEdges[n-1] = true;
      }
    } else fill((255 * edgesPerClique[nodeInClique[n-1]])/maxCliqueSize, 0, 0);
    pushMatrix();
    //translate(p.x, p.y, p.z);
    translate(p.x, p.y);
    textSize(25);
    text(n, 10 * nodeInClique[n-2], 10 * nodeInClique[n-2]);
    float size = 1 + (35 * edgesPerClique[nodeInClique[n-1]]/maxCliqueSize);
    //size = 20;
    square(0 -size/2, 0 - size/2, size);
    //polygon(0, 0, size, edgesPerClique[nodeInClique[n-1]]);
    popMatrix();
  }
}

void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

class ParticleSystem
{
  Particle[] pcls;
  int num;
  void init(int n)
  {
    num = n;
    pcls = new Particle[n];
    for (int i=0; i<n; i++)
      pcls[i] = new Particle();
  }

  void resetForces()
  {
    for (int i=0; i<num; i++)
    {
      pcls[i].f.x = 0;
      pcls[i].f.y = 0;
      pcls[i].f.z = 0;
    }
  }

  void applyForces(float ts) //EULER
  {
    for (int i=0; i<num; i++)
    {
      pcls[i].v.x += ts * pcls[i].f.x;
      pcls[i].v.y += ts * pcls[i].f.y;
      pcls[i].v.z += ts * pcls[i].f.z;

      pcls[i].p.x += ts * pcls[i].v.x;
      pcls[i].p.y += ts * pcls[i].v.y;
      pcls[i].p.z += ts * pcls[i].v.z;
    }
  }

  void applyForcesMP(float ts) //mid-point
  {
    for (int i=0; i<num; i++)
    {
      Vec3d v, p;

      pcls[i].v.x += 0.5* ts * pcls[i].f.x;
      pcls[i].v.y += 0.5* ts * pcls[i].f.y;
      pcls[i].v.z += 0.5* ts * pcls[i].f.z;

      pcls[i].p.x += ts * pcls[i].v.x;
      pcls[i].p.y += ts * pcls[i].v.y;
      pcls[i].p.z += ts * pcls[i].v.z;
    }
  }


  void addForce(int i, Vec3d ff)
  {
    pcls[i].f.x += ff.x;
    pcls[i].f.y += ff.y;
    pcls[i].f.z += ff.z;
  }

  void draw()
  {
    if (!abstraction)
    {
      for (int i=0; i<num; i++)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[i] && minEdges[i]) pcls[i].draw(i+1);
        }
        if (filtrationTechnique == "KCores")
        {
          if (nodes1[i] && KCore[i]) pcls[i].draw(i+1);
        }
      }
    } else
    {
      for (int i=0; i<num; i++)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodeInClique[i] == -1)
          {
            if (nodes1[i] && minEdges[i]) pcls[i].draw(i+1);
          } else
          {
            //cliqueIndex
            //nodeInClique
            if (nodes1[i] && minEdges[i] && i == cliqueIndex[nodeInClique[i]]) pcls[i].drawClique(i+1);
          }
        }
        if (filtrationTechnique == "KCores")
        {
          if (nodeInClique[i] == -1)
          {
            if (nodes1[i] && KCore[i]) pcls[i].draw(i+1);
          } else
          {
            if (nodes1[i] && KCore[i] && i == cliqueIndex[nodeInClique[i]]) pcls[i].drawClique(i+1);
          }
        }
      }
    }
  }
};

ParticleSystem[] sys;

Vec3d p;
Vec3d v;
Vec3d f;

float damp = 0.01;

int num_pcls = 0;

void setup()
{
  //maxCliqueSize = 1;
  sys = new ParticleSystem[6];
  a = new Float[2];
  b = new Float[2];
  PFont.list();
  table = loadTable(FILE_NAME + "\\" + FILE_NAME+".csv", "header");
  num_links = table.getRowCount();
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0);
    int n2 = row.getInt(1);
    num_pcls = max(num_pcls, n1);
    num_pcls = max(num_pcls, n2);
  }
  num_nodes1 = num_pcls;
  node_forces = new Vec3d[num_pcls+1];
  nodes1 = new boolean[num_pcls+1];
  highlightEdges = new boolean[num_pcls+1];
  nodeInClique = new int[num_pcls+1];
  for (int i = 0; i < num_pcls; i++) nodeInClique[i] = -1;
  for (int i = 0; i < num_pcls; i++) nodes1[i] = true;

  leftBorder = -width/2 + offset;
  rightBorder = width/2 - offset - uiOffset;
  topBorder = -height/2 + offset;
  bottomBorder = height/2 - offset;

  num_pcls+=1;
  for (int i = 0; i < 6; i++)
  {
    sys[i] = new ParticleSystem();
    sys[i].init(num_pcls);

    sys[i].pcls[0].p.x = leftBorder + (rightBorder - leftBorder)/2;
    sys[i].pcls[0].p.y = topBorder + (bottomBorder - topBorder)/2;
    sys[i].pcls[0].p.z = random(0);

    for (int j = 0; j < sliderOffset.length; j++) sliderOffset[j] = 0;

    for (int j = 1; j < num_pcls; j++)
    {
      sys[i].pcls[j].p.x = random(leftBorder, rightBorder);
      sys[i].pcls[j].p.y = random(topBorder, bottomBorder);
      sys[i].pcls[j].p.z = random(0);
    }
  }

  findMaxKCore(table);
  KCore = findKCores(table, 0);
  minEdges = findMinEdges(table, 0);
  findMinEdges(table, 0);
  findMaxKCore(table);

  fullScreen(OPENGL);

  p = new Vec3d();
  v = new Vec3d(0, 0, 0);
  f = new Vec3d(0, 0, 0);

  p.x = -20;
  p.y = -60;
  p.z = 0;

  totalCliques = 0;
  //currentValue[2] = int(loadStrings(FILE_NAME + '\\' + FILE_NAME + "_max_clique_size.txt")[0]);
  currentValue[2] = 3;
  currentValue[3] = int(loadStrings(FILE_NAME + '\\' + FILE_NAME + "_max_clique_size.txt")[0]);
  currentValue[4] = int(loadStrings(FILE_NAME + '\\' + FILE_NAME + "_max_clique_size.txt")[0]);
  loadCliques();
  storeCliques();
  for (int i = 0; i < nodeInClique.length; i++) println(str(i) + ": " + str(nodeInClique[i]));
}

float veclen(Vec3d p)
{
  return sqrt(p.x*p.x+p.y*p.y+p.z*p.z);
}


void pcl_spring1(int a, int b, float slen, float k, float df) //asymmetric spring between two particles only b moves
  //slen = equilibrium length
  //k = spring constant
  //df = damping factor
{
  p.x = sys[0].pcls[b].p.x - sys[0].pcls[a].p.x;
  p.y = sys[0].pcls[b].p.y - sys[0].pcls[a].p.y;
  p.z = sys[0].pcls[b].p.z - sys[0].pcls[a].p.z;

  //float slen = 50;
  float ex = veclen(p);
  float mg = ex - slen;

  float nx = p.x/ex;
  float ny = p.y/ex;
  float nz = p.z/ex;

  //float k = .003;

  f.x = 0;
  f.y = 0;
  f.z = 0;

  f.x += -k*mg*nx;
  f.y += -k*mg*ny;
  f.z += -k*mg*nz;

  f.x += -df * sys[0].pcls[b].v.x-sys[0].pcls[a].v.x;
  f.y += -df * sys[0].pcls[b].v.y-sys[0].pcls[a].v.y;
  f.z += -df * sys[0].pcls[b].v.z-sys[0].pcls[a].v.z;

  sys[0].addForce(b, f);
}

void pcl_spring(int a, int b, float slen, float k, float df) //symmetric spring between two particles
  //slen = equilibrium length
  //k = spring constant
  //df = damping factor
{
  p.x = sys[0].pcls[a].p.x - sys[0].pcls[b].p.x;
  p.y = sys[0].pcls[a].p.y - sys[0].pcls[b].p.y;
  p.z = sys[0].pcls[a].p.z - sys[0].pcls[b].p.z;

  //float slen = 50;
  float ex = veclen(p);
  float mg = ex - slen;

  float nx = p.x/ex;
  float ny = p.y/ex;
  float nz = p.z/ex;

  //float k = .003;

  f.x = 0;
  f.y = 0;
  f.z = 0;

  f.x += -k*mg*nx;
  f.y += -k*mg*ny;
  f.z += -k*mg*nz;

  /////////////////////
  Vec3d f1 = new Vec3d(0, 0, 0);

  f1.x = 0.5 *f.x;
  f1.y = 0.5 *f.y;
  f1.z = 0.5 *f.z;

  f1.x += -df*sys[0].pcls[a].v.x;
  f1.y += -df*sys[0].pcls[a].v.y;
  f1.z += -df*sys[0].pcls[a].v.z;

  sys[0].addForce(a, f1);

  f.x *=-0.5;
  f.y *=-0.5;
  f.z *=-0.5;

  f.x += -df*sys[0].pcls[b].v.x;
  f.y += -df*sys[0].pcls[b].v.y;
  f.z += -df*sys[0].pcls[b].v.z;


  sys[0].addForce(b, f);
}

int holdp;

void draw()
{
  background(255);
  translate(width/2, height/2);
  //rotate(45, 1, 0, 0);
  //scale(1, -1);
  int offset = 1;
  line(-width/2 + offset,-height/2,-width/2 + offset,height/2);
  line(-width/2,-height/2 + offset,width/2,-height/2 + offset);
  line(-width/2,height/2 - offset,width/2,height/2 - offset);

  if (graphType == "Network")networkGraph(true);
  else if (graphType == "Matrix")adjacencyMatrix(true);
  else if (graphType == "Arc")arcGraph(true);
  else if (graphType == "BaseRadical")basicRadical(true);
  else if (graphType == "CurveRadical")curveRadical(true);

  //fill(0);
  //stroke(0);

  if (scroll > 0) scroll = 0;
  else if(scroll < -120) scroll = -120;

  stroke(0);

  fill(230, 230, 230);
  noStroke();
  line(width/2 - uiOffset, -height/2, width/2 - uiOffset, -height/4);
  rect(width/2 - uiOffset, -height/2, width, height);
  if (!sliderSelected) fill(210);
  else fill(180);
  stroke(10);
  line(width/2 - uiOffset, -height/2, width/2 - uiOffset, -height/4);
  line(width/2 - uiOffset, height/4, width/2 - uiOffset, height/2);
  rect(width/2 - sliderWidth/2 - uiOffset, -height/4, sliderWidth, height/2, sliderWidth/2);

  fill(210);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(7 * height/16) + scroll, width/2, 3 * height/32, 1 * height/32);

  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(5 * height/16) + scroll, width/2 - 200, 3 * height/64, 1 * height/64);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(5 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -(5 * height/16) + 3 * height/128 + scroll);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(5 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(5 * height/16) + 3 * height/128 + scroll);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(5 * height/16) + scroll, 190, 3 * height/64, 1 * height/64);

  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(4 * height/16) + scroll, width/2 - 200, 3 * height/64, 1 * height/64);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(4 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -(4 * height/16) + 3 * height/128 + scroll);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(4 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(4 * height/16) + 3 * height/128 + scroll);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(4 * height/16) + scroll, 190, 3 * height/64, 1 * height/64);

  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(3 * height/16) + scroll, width/2 - 200, 3 * height/64, 1 * height/64);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(3 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -(3 * height/16) + 3 * height/128 + scroll);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(3 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(3 * height/16) + 3 * height/128 + scroll);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(3 * height/16) + scroll, 190, 3 * height/64, 1 * height/64);

  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(2 * height/16) + scroll, width/2 - 200, 3 * height/64, 1 * height/64);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(2 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -(2 * height/16) + 3 * height/128 + scroll);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(2 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(2 * height/16) + 3 * height/128 + scroll);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(2 * height/16) + scroll, 190, 3 * height/64, 1 * height/64);

  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(1 * height/16) + scroll, width/2 - 200, 3 * height/64, 1 * height/64);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(1 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -(1 * height/16) + 3 * height/128 + scroll);
  line(width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(1 * height/16) + scroll, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -(1 * height/16) + 3 * height/128 + scroll);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(1 * height/16) + scroll, 190, 3 * height/64, 1 * height/64);

  if (graphType == "Network") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(1 * height/16) + scroll  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);
  if (graphType == "Matrix") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3, -(1 * height/16) + scroll  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);
  if (graphType == "Arc") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3, -(1 * height/16) + scroll  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);

  if (graphType == "BaseRadical") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100, -(1 * height/16) + (width-40)/6 + scroll + 10  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);
  if (graphType == "CurveRadical") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3, -(1 * height/16) + (width-40)/6 + scroll + 10  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);
  if (graphType == "NA") strokeWeight(3);
  else strokeWeight(1);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3, -(1 * height/16) + (width-40)/6 + scroll + 10  +(1 * height/16), (width-40)/6, (width-40)/6, 1 * height/32);

  strokeWeight(1);

  if (sliders[0]) fill(150);
  else fill(190);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + sliderOffset[0], -(5 * height/16) + scroll, 50, 3 * height/64, 1 * height/64);
  if (sliders[1]) fill(150);
  else fill(190);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + sliderOffset[1], -(4 * height/16) + scroll, 50, 3 * height/64, 1 * height/64);
  if (sliders[2]) fill(150);
  else fill(190);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + sliderOffset[2], -(3 * height/16) + scroll, 50, 3 * height/64, 1 * height/64);
  if (sliders[3]) fill(150);
  else fill(190);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + sliderOffset[3], -(2 * height/16) + scroll, 50, 3 * height/64, 1 * height/64);
  if (sliders[4]) fill(150);
  else fill(190);
  rect(width/2 - sliderWidth/2 - uiOffset + 100 + 200 + sliderOffset[4], -(1 * height/16) + scroll, 50, 3 * height/64, 1 * height/64);

  fill(0);
  textSize(15);
  textAlign(CENTER, CENTER);
  text(maxMinEdges, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(5 * height/16) -5 + scroll);
  text("0", width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(5 * height/16) - 5 + scroll);
  text(maxKCore, width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(4 * height/16) -5 + scroll);
  text("0", width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(4 * height/16) - 5 + scroll);
  text("3", width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(3 * height/16) -5 + scroll);
  text(maxCliqueSize, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(3 * height/16) - 5 + scroll);
  text("3", width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(2 * height/16) -5 + scroll);
  text(maxCliqueSize, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(2 * height/16) - 5 + scroll);
  text("3", width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200, -5 -(1 * height/16) -5 + scroll);
  text(maxCliqueSize, width/2 - sliderWidth/2 - uiOffset + 100 + 200, -5 -(1 * height/16) - 5 + scroll);
  textSize(20);
  textAlign(BASELINE);
  text("Mode:", width/2 - sliderWidth/2 - uiOffset + 120, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  text("Basic", width/2 - sliderWidth/2 - uiOffset + 200, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  text("Highlight", width/2 - sliderWidth/2 - uiOffset + 200, -(6.5 * height/16) + 3 * height/64 + 5 + scroll);
  text("Filter", width/2 - sliderWidth/2 - uiOffset + 300, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  text("Reset Filter", width/2 - sliderWidth/2 - uiOffset + 400, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  text("No Edges", width/2 - sliderWidth/2 - uiOffset + 550, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  //text("Filtration:", width/2 - sliderWidth/2 - uiOffset + 700, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  //text("Edges", width/2 - sliderWidth/2 - uiOffset + 800, -(7 * height/16) + 3 * height/64 + 5 + scroll);
  text("Cliques", width/2 - sliderWidth/2 - uiOffset + 900, -(7 * height/16) + 3 * height/64 + 5 + scroll);

  text("Degree Centrality  ="+currentValue[0], width/2 - sliderWidth/2 - uiOffset + 105, -(5 * height/16) + 3 * height/64 - 10 + scroll);
  text("K-Cores            ="+currentValue[1], width/2 - sliderWidth/2 - uiOffset + 105, -(4 * height/16) + 3 * height/64 - 10 + scroll);
  text("Clique Degree      ="+currentValue[2], width/2 - sliderWidth/2 - uiOffset + 105, -(3 * height/16) + 3 * height/64 - 10 + scroll);
  text("Clique Betweenness="+currentValue[3], width/2 - sliderWidth/2 - uiOffset + 105, -(2 * height/16) + 3 * height/64 - 10 + scroll);
  text("Clique Closeness   ="+currentValue[4], width/2 - sliderWidth/2 - uiOffset + 105, -(1 * height/16) + 3 * height/64 - 10 + scroll);
  //text("UNUSED", width/2 - sliderWidth/2 - uiOffset + 105, -(2 * height/16) + 3 * height/64 - 10 + scroll);

  if (mode == "Basic")
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 275 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  if (mode == "Filter")
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 375 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  if (mode == "Highlight")
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 300 + 20/2, -(6.5 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  
  if (filtrationTechnique == "MinEdges")
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(2 * height/16), 20);
  if (filtrationTechnique == "KCores")
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(1 * height/16), 20);
  if (cliqueSet == 0)
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(0 * height/16), 20);
  if (cliqueSet == 1)
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-1 * height/16), 20);
  if (cliqueSet == 2)
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-2 * height/16), 20);

  fill(200, 0, 0);
  strokeWeight(3);
  circle(width/2 - sliderWidth/2 - uiOffset + 525 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  circle(width/2 - sliderWidth/2 - uiOffset + 645 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  fill(175);
  //circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  //if (filtrationTechnique == "MinEdges")
  //{
  //  fill(0, 0, 255);
  //  strokeWeight(3);
  //} else
  //{
  //  fill(255);
  //  strokeWeight(1);
  //}

  //circle(width/2 - sliderWidth/2 - uiOffset + 875 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  if (abstraction)
  {
    fill(0, 0, 255);
    strokeWeight(3);
  } else
  {
    fill(255);
    strokeWeight(1);
  }
  circle(width/2 - sliderWidth/2 - uiOffset + 975 + 20/2, -(7 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  strokeWeight(1);

  pushMatrix();
  translate(width/2 - sliderWidth/2 - uiOffset + 100 + ((width-40)/6)/2, -(1 * height/16) +(1 * height/16) + scroll + ((width-40)/6)/2);
  //circle(0,0,10);
  scale(0.16);
  networkGraph(false);
  popMatrix();

  pushMatrix();
  translate(width/2 - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 + ((width-40)/6)/2, -(1 * height/16) + scroll +(1 * height/16) + ((width-40)/6)/2);
  //circle(0,0,10);
  scale(0.2);
  adjacencyMatrix(false);
  popMatrix();

  pushMatrix();
  translate(width/2 - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3 + ((width-40)/6)/2, -(1 * height/16) + scroll +(1 * height/16) + ((width-40)/6)/2);
  //circle(0,0,10);
  scale(0.16);
  arcGraph(false);
  popMatrix();

  pushMatrix();
  translate(width/2 - sliderWidth/2 - uiOffset + 100 + ((width-40)/6)/2, -(1 * height/16) + scroll +(1 * height/16) + ((width-40)/6)/2 + (width-40)/6 + 10);
  //circle(0,0,10);
  scale(0.3);
  basicRadical(false);
  popMatrix();

  pushMatrix();
  translate(width/2 - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 + ((width-40)/6)/2, -(1 * height/16) + scroll +(1 * height/16) + ((width-40)/6)/2 + (width-40)/6 + 10);
  //circle(0,0,10);
  scale(0.3);
  curveRadical(false);
  popMatrix();


  storeCliques();

  if (second() >= 30) println(float(frameCount)/float(millis() / 1000));
}

void drawlink(int a, int b, int i)
{
  if ((highlightEdges[a] || highlightEdges[b]))
  {
    strokeWeight(3);
    stroke(150, 100, 100);
  } else
  {
    strokeWeight(1);
    stroke(0);
  }
  if (nodes1[a] && nodes1[b]) line (sys[i].pcls[a].p.x, sys[i].pcls[a].p.y, sys[i].pcls[b].p.x, sys[i].pcls[b].p.y);
  //line (sys.pcls[a].p.x, sys.pcls[a].p.y,  sys.pcls[a].p.z, sys.pcls[b].p.x, sys.pcls[b].p.y, sys.pcls[b].p.z);
  stroke(0);
  strokeWeight(1);
}

void keyPressed()
{
  if (key == '1')graphType = "Network";
  else if (key == '2')graphType = "Matrix";
  else if (key == '3')graphType = "Arc";
  else if (key == '4')graphType = "BaseRadical";
  else if (key == '5')graphType = "CurveRadical";
  else if (key == '6')cliqueSet = 0;
  else if (key == '7')cliqueSet = 1;
  else if (key == '8')cliqueSet = 2;
  if (key == ' ')
  {
    sys[0].pcls[num_pcls-1].v.x += 10;
    sys[0].pcls[num_pcls-1].v.y += 15;
  }
  lastHolder = -1;
  
  if(key == 's') save(FILE_NAME + "_" + filtrationTechnique +"_" + currentValue[1] + ".png");
}


void pcl_collisions()
{
  for (int i=1; i<num_pcls; i++)
  {

    float ex = sys[0].pcls[i].p.y - bottomBorder;

    if  (ex > 0)
    {

      ///////////////////////////////

      float k = .5;

      Vec3d f1 = new Vec3d(0, 0, 0);
      f1.y += -k * ex;

      f1.y += -.05*sys[0].pcls[i].v.y; //damping
      sys[0].addForce(i, f1);

      ///////////////////////////////
    }

    ex = topBorder - sys[0].pcls[i].p.y;

    if  (ex > 0)
    {

      ///////////////////////////////

      float k = .5;

      Vec3d f1 = new Vec3d(0, 0, 0);
      f1.y += k * ex;

      f1.y += -.05*sys[0].pcls[i].v.y; //damping
      sys[0].addForce(i, f1);

      ///////////////////////////////
    }



    ex = sys[0].pcls[i].p.x - rightBorder+10;

    if  (ex > 0)
    {

      ///////////////////////////////

      float k = .05;

      Vec3d f1 = new Vec3d(0, 0, 0);
      f1.x -= k * ex;

      f1.x += -.05*sys[0].pcls[i].v.x; //damping
      sys[0].addForce(i, f1);

      ///////////////////////////////
    }

    ex =  leftBorder - sys[0].pcls[i].p.x;

    if  (ex > 0)
    {

      ///////////////////////////////

      float k = .05;

      Vec3d f1 = new Vec3d(0, 0, 0);
      f1.x += k * ex;

      f1.x += -.015*sys[0].pcls[i].v.x; //damping
      sys[0].addForce(i, f1);

      ///////////////////////////////
    }
  }
}

boolean mouseHold = false;

void mouseReleased()
{
  mouseHold = false;
  sliderSelected = false;
  olduiOffset = uiOffset;
  clicked = false;
  for (int i = 0; i < sliders.length; i++) sliders[i] = false;

  updateSliders();
}

void mousePressed()
{
  updateSliders();
  stroke(0);
  // && mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 -10
  if (mouseX >  width - sliderWidth/2 - uiOffset + 275 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 275 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll) mode = "Basic";
  if (mouseX >  width - sliderWidth/2 - uiOffset + 375 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 375 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll) mode = "Filter";
  if (mouseX >  width - sliderWidth/2 - uiOffset + 300 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 300 + 20/2 + 10 &&
    mouseY > height/2 -(6.5 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(6.5 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll) mode = "Highlight";
  if (mouseX >  width - sliderWidth/2 - uiOffset + 525 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 525 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll)
  {
    for (int i = 0; i < nodes1.length; i++) nodes1[i] = true;
    for (int i = 0; i < highlightEdges.length; i++) highlightEdges[i] = false;
    findMaxKCore(table);
    KCore = findKCores(table, 0);
    minEdges = findMinEdges(table, 0);
    findMinEdges(table, 0);
    findMaxKCore(table);
  }
  if (mouseX >  width - sliderWidth/2 - uiOffset + 645 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 645 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll) for (int i =0; i < edgesPerNode.length; i++) if (edgesPerNode[i] < 1) nodes1[i] = false;
  if (mouseX >  width - sliderWidth/2 - uiOffset + 875 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 875 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll)
  {
    filtrationTechnique = "MinEdges";
  }
  //if (mouseX > width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10
  //  && mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll + 10)
  //{
  //  abstraction = !abstraction;
  //}

  if (mouseX >  width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10 &&
    mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(2 * height/16) - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(2 * height/16) + 10) filtrationTechnique = "MinEdges";
  if (mouseX >  width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10 &&
    mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(1 * height/16) - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(1 * height/16) + 10) filtrationTechnique = "KCores";
  if (mouseX >  width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10 &&
    mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(0 * height/16) - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(0 * height/16) + 10) cliqueSet = 0;
  if (mouseX >  width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10 &&
    mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-1 * height/16) - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-1 * height/16) + 10) cliqueSet = 1;
  if (mouseX >  width - sliderWidth/2 - uiOffset + 65 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 65 + 20/2 + 10 &&
    mouseY > height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-2 * height/16) - 10 && mouseY < height/2 -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll -(-2 * height/16) + 10) cliqueSet = 2;
  
  lastHolder = -1;
  //storeCliques();

  //circle(width/2 - sliderWidth/2 - uiOffset + 65 + 20/2, -(3.25 * height/16) + (3 * height/32)/2 - 3 + scroll, 20);
  if (mouseX >  width - sliderWidth/2 - uiOffset + 975 + 20/2 -10 && mouseX < width - sliderWidth/2 - uiOffset + 975 + 20/2 + 10 &&
    mouseY > height/2 -(7 * height/16) + (3 * height/32)/2 - 3 - 10 + scroll && mouseY < height/2 -(7 * height/16) + (3 * height/32)/2 - 3 + 10 + scroll)
  {
    abstraction = !abstraction;
  }
  if (mode == "Filter" || mode == "Highlight")
  {
    if (!clicked) clicked = true;
    else clicked=false;
  }
  if (mouseX > width - sliderWidth/2 - uiOffset && mouseX < width + sliderWidth/2 - uiOffset && mouseY > height/4  + scroll&& mouseY < (3 * height)/4 + scroll)
  {
    sliderSelected = true;
    originalPos = mouseX;
  }
  if (mouseX > sliderOffset[0] + width - sliderWidth/2 - uiOffset + 100 + 200 && mouseX < sliderOffset[0] + width - sliderWidth/2 - uiOffset + 100 + 200 + 3 * height/64
    && mouseY > -(5 * height/16) + height/2 + scroll && mouseY < -(5 * height/16) + height/2 + 3 * height/64 + scroll) sliders[0] = true;
  if (mouseX > sliderOffset[1] +width - sliderWidth/2 - uiOffset + 100 + 200 && mouseX < sliderOffset[1] + width - sliderWidth/2 - uiOffset + 100 + 200 + 3 * height/64
    && mouseY > -(4 * height/16) + height/2 + scroll && mouseY < -(4 * height/16) + height/2 + 3 * height/64 + scroll) sliders[1] = true;
  if (mouseX > sliderOffset[2] +width - sliderWidth/2 - uiOffset + 100 + 200 && mouseX < sliderOffset[2] + width - sliderWidth/2 - uiOffset + 100 + 200 + 3 * height/64
    && mouseY > -(3 * height/16) + height/2 + scroll && mouseY < -(3 * height/16) + height/2 + 3 * height/64 + scroll) sliders[2] = true;
  if (mouseX > sliderOffset[3] +width - sliderWidth/2 - uiOffset + 100 + 200 && mouseX < sliderOffset[3] + width - sliderWidth/2 - uiOffset + 100 + 200 + 3 * height/64
    && mouseY > -(2 * height/16) + height/2 + scroll && mouseY < -(2 * height/16) + height/2 + 3 * height/64 + scroll) sliders[3] = true;
  if (mouseX > sliderOffset[4] +width - sliderWidth/2 - uiOffset + 100 + 200 && mouseX < sliderOffset[4] + width - sliderWidth/2 - uiOffset + 100 + 200 + 3 * height/64
    && mouseY > -(1 * height/16) + height/2 + scroll && mouseY < -(1 * height/16) + height/2 + 3 * height/64 + scroll) sliders[4] = true;

  if (mouseX > width - sliderWidth/2 - uiOffset + 100 && mouseX < width - sliderWidth/2 - uiOffset + 100 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll && mouseY < height/2 -(1 * height/16) + scroll + (width-40)/6 )graphType = "Network";
  if (mouseX > width - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 && mouseX < width - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll && mouseY < height/2 -(1 * height/16) + scroll + (width-40)/6 )graphType = "Matrix";
  if (mouseX > width - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3 && mouseX < width - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll && mouseY < height/2 -(1 * height/16) + scroll + (width-40)/6 )graphType = "Arc";

  if (mouseX > width - sliderWidth/2 - uiOffset + 100 && mouseX < width - sliderWidth/2 - uiOffset + 100 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll + (width-40)/6 + 10 && mouseY < height/2 -(1 * height/16) + scroll  + (width-40)/6 + 10 + (width-40)/6 )graphType = "BaseRadical";
  if (mouseX > width - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 && mouseX < width - sliderWidth/2 - uiOffset + 100 + (width/6) + 10/3 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll + (width-40)/6 + 10 && mouseY < height/2 -(1 * height/16) + scroll + (width-40)/6 + 10 + (width-40)/6 )graphType = "CurveRadical";
  if (mouseX > width - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3 && mouseX < width - sliderWidth/2 - uiOffset + 100 + 2 * (width/6) + 20/3 + (width-40)/6
    && mouseY > height/2 -(1 * height/16) + scroll + (width-40)/6 + 10 && mouseY < height/2 -(1 * height/16) + scroll + (width-40)/6 + 10 + (width-40)/6 )graphType = "NA";

  if (mode == "Basic")
  {
    if (mouseX < rightBorder + width && !sliderSelected && mouseX < width - sliderWidth/2 - uiOffset)
    {
      mouseHold = true;

      float mind = (sys[0].pcls[1].p.x - sys[0].pcls[0].p.x) * (sys[0].pcls[1].p.x - sys[0].pcls[0].p.x)
        +(sys[0].pcls[1].p.y - sys[0].pcls[0].p.y) * (sys[0].pcls[1].p.y - sys[0].pcls[0].p.y);
      ;
      float d;
      int md = 1;

      for (int i=2; i<num_pcls; i++)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[i-1] && minEdges[i-1])
          {
            d = (sys[0].pcls[i].p.x - sys[0].pcls[0].p.x) * (sys[0].pcls[i].p.x - sys[0].pcls[0].p.x)
              +(sys[0].pcls[i].p.y - sys[0].pcls[0].p.y) * (sys[0].pcls[i].p.y - sys[0].pcls[0].p.y);

            if (d<mind)
            {
              md = i;
              mind = d;
            }
          }
        }
        if (filtrationTechnique == "KCores")
        {
          if (nodes1[i-1] && KCore[i-1])
          {
            d = (sys[0].pcls[i].p.x - sys[0].pcls[0].p.x) * (sys[0].pcls[i].p.x - sys[0].pcls[0].p.x)
              +(sys[0].pcls[i].p.y - sys[0].pcls[0].p.y) * (sys[0].pcls[i].p.y - sys[0].pcls[0].p.y);

            if (d<mind)
            {
              md = i;
              mind = d;
            }
          }
        }
      }

      holdp = md;

      sys[0].pcls[0].p.x = mouseX - width/2;
      sys[0].pcls[0].p.y = -(height - (mouseY + height/2));
    }
  }
  updateSliders();
}
//width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 200

void mouseDragged()
{
  if (mode == "Filter") clicked = false;
  for (int i = 0; i < sliderOffset.length; i++)
  {
    if (sliders[i])
    {
      if (mouseX < width/2 - sliderWidth/2 - uiOffset + 100 + 200 + width/2) sliderOffset[i] = 0;
      else if (mouseX > width - sliderWidth/2 - uiOffset + 100 + 200 + width/2 - 250) sliderOffset[i] = width/2 - 200 - 50;
      else sliderOffset[i] = mouseX - (width - sliderWidth/2 - uiOffset + 100 + 200);
      if (i == 0)currentValue[i] = int((sliderOffset[i]/(width/2 - 250)) * maxMinEdges);
      if (i == 1)currentValue[i] = int((sliderOffset[i]/(width/2 - 250)) * maxKCore);
      if (i == 2) currentValue[i] = maxCliqueSize - int((sliderOffset[i]/(width/2 - 250)) * (maxCliqueSize - 3));
      if (i == 3)currentValue[i] = maxCliqueSize - int((sliderOffset[i]/(width/2 - 250)) * (maxCliqueSize - 3));
      if (i == 4)currentValue[i] = maxCliqueSize - int((sliderOffset[i]/(width/2 - 250)) * (maxCliqueSize - 3));
    }
  }
  if (mode == "Basic")
  {
    if (mouseX < rightBorder + width/2 && !sliderSelected)
    {
      sys[0].pcls[0].p.x = mouseX - width/2;
      sys[0].pcls[0].p.y = -(height - (mouseY + height/2));
      if (sys[0].pcls[0].p.x < leftBorder - 50)
      {
        sys[0].pcls[0].p.x = leftBorder - 50;
      }
      if (sys[0].pcls[0].p.x > rightBorder + 50)
      {
        sys[0].pcls[0].p.x = rightBorder + 50;
      }
      if (sys[0].pcls[0].p.y < topBorder - 50)
      {
        sys[0].pcls[0].p.y = topBorder - 50;
      }
      if (sys[0].pcls[0].p.y > bottomBorder + 50)
      {
        sys[0].pcls[0].p.y = bottomBorder + 50;
      }
    }
  }
  if (sliderSelected)
  {
    uiOffset = olduiOffset + originalPos - mouseX;
    rightBorder = width/2 - offset - uiOffset;
  }
}

void accumulateForces()
{
  Vec3d f = new Vec3d();
  for (int i = 0; i < num_pcls; i++)
  {
    node_forces[i] = new Vec3d(0, 0, 0);
  }
  for (TableRow row : table.rows())
  {
    int i = row.getInt(0)-1;
    int j = row.getInt(1)-1;
    f.x = sys[0].pcls[i].p.x - sys[0].pcls[j].p.x;
    f.y = sys[0].pcls[i].p.y - sys[0].pcls[j].p.x;
    f.z = sys[0].pcls[i].p.z - sys[0].pcls[j].p.x;
    if (sqrt(f.x*f.x + f.y*f.y + f.z*f.z) < 50)
    {
      node_forces[i].x -= 1*f.x;
      node_forces[i].y -= 1*f.y;
      node_forces[i].z -= 1*f.z;
      node_forces[j].x += 1*f.x;
      node_forces[j].y += 1*f.y;
      node_forces[j].z += 1*f.z;
    }
    for (int x=0; x<num_nodes; x++)
    {
      for (int y=x+1; y<num_nodes; y++)
      {
        f.x = sys[0].pcls[x].p.x - sys[0].pcls[y].p.x;
        f.y = sys[0].pcls[x].p.y - sys[0].pcls[y].p.x;
        f.z = sys[0].pcls[x].p.z - sys[0].pcls[y].p.x;
        if (sqrt(f.x*f.x + f.y*f.y)<150)
        {
          node_forces[i].x += f.x;
          node_forces[i].y += f.y;
          node_forces[i].z += f.z;
          node_forces[j].x -= f.x;
          node_forces[j].y -= f.y;
          node_forces[j].z -= f.z;
        }
        if (sqrt(f.x*f.x + f.y*f.y)<40)
        {
          node_forces[i].x += 80*f.x;
          node_forces[i].y += 80*f.y;
          node_forces[i].z += 80*f.z;
          node_forces[j].x -= 80*f.x;
          node_forces[j].y -= 80*f.y;
          node_forces[j].z -= 80*f.z;
        }
      }
    }
  }
}

boolean[] findMinEdges(Table tbl, int minEdges)
{
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0);
    int n2 = row.getInt(1);
    num_pcls = max(num_pcls, n1);
    num_pcls = max(num_pcls, n2);
  }
  int rows = num_pcls;
  boolean[] nodeHasMinEdges = new boolean[rows];
  Arrays.fill(nodeHasMinEdges, true);
  edgesPerNode = new int [rows];
  for (TableRow row : tbl.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    if (nodeHasMinEdges[n1] && nodeHasMinEdges[n2] && nodes1[n1] && nodes1[n2])
    {
      if (nodes1[n1] && nodes1[n2])
      {
        edgesPerNode[n1]++;
        edgesPerNode[n2]++;
      }
    }
  }
  for (int i = 0; i < nodeHasMinEdges.length; i++)
  {
    if (edgesPerNode[i] < minEdges)
    {
      nodeHasMinEdges[i] = false;
    }
  }
  maxMinEdges = -1;
  int secondLeastEdges = -1;
  for (int i = 0; i < edgesPerNode.length; i++)
  {
    if (edgesPerNode[i] >= maxMinEdges) maxMinEdges = edgesPerNode[i];
    else if (edgesPerNode[i] > secondLeastEdges) secondLeastEdges = edgesPerNode[i];
  }
  maxMinEdges = secondLeastEdges;
  return nodeHasMinEdges;
}

boolean[] findKCores(Table tbl, int kCores)
{
  boolean nothingChanged = false;
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0);
    int n2 = row.getInt(1);
    num_pcls = max(num_pcls, n1);
    num_pcls = max(num_pcls, n2);
  }
  int rows = num_pcls+1;
  boolean[] nodeInKCore = new boolean[rows];
  Arrays.fill(nodeInKCore, true);
  int[] edgesPerNodeInTbl = new int [rows];
  while (!nothingChanged)
  {
    nothingChanged = true;
    edgesPerNodeInTbl = new int [rows];
    for (TableRow row : tbl.rows())
    {
      int n1 = row.getInt(0)-1;
      int n2 = row.getInt(1)-1;
      if (nodeInKCore[n1] && nodeInKCore[n2] && nodes1[n1] && nodes1[n2])
      {
        if (nodes1[n1] && nodes1[n2])
        {
          edgesPerNodeInTbl[n1]++;
          edgesPerNodeInTbl[n2]++;
        }
      }
    }
    for (int i = 0; i < edgesPerNodeInTbl.length; i++)
    {
      if (edgesPerNodeInTbl[i] < kCores && nodeInKCore[i])
      {
        nothingChanged = false;
        nodeInKCore[i] = false;
      }
    }
  }
  return nodeInKCore;
}

void update()
{
  for (int i=0; i<num_nodes; i++)
  {
    sys[0].pcls[i].p.x += 0.01*node_forces[i].x;
    sys[0].pcls[i].p.y += 0.01*node_forces[i].y;
    sys[0].pcls[i].p.z += 0.01*node_forces[i].z;
  }
}

void findMaxKCore(Table table)
{
  boolean finished = false;
  int j = 0;
  boolean[] holderArray;
  while (!finished)
  {
    finished = true;
    holderArray = findKCores(table, j);
    for (int k = 0; k < holderArray.length; k++)
    {
      if (holderArray[k])
      {
        finished = false;
        j++;
        break;
      }
    }
  }
  maxKCore = j-1;
}

void updateSliders()
{
  KCore = findKCores(table, currentValue[1]);
  findMaxKCore(table);
  minEdges = findMinEdges(table, currentValue[0]);
  for (int i = 0; i < currentValue.length; i++)
  {
    if (i == 0)currentValue[i] = int((sliderOffset[i]/(width/2 - 250)) * maxMinEdges);
    if (i == 1)currentValue[i] = int((sliderOffset[i]/(width/2 - 250)) * maxKCore);
  }
}

void networkGraph(boolean main)
{
  updateSliders();
  fill (255, 0, 0);



  sys[0].resetForces();
  for (int j=1; j<num_pcls; j++)
  {
    if (filtrationTechnique == "MinEdges")if (nodes1[j] && minEdges[j]) sys[0].pcls[j].f.y += 0;
    if (filtrationTechnique == "KCores")if (nodes1[j] && KCore[j]) sys[0].pcls[j].f.y += 0;
  }

  if (mouseHold && main)
  {
    stroke(0, 0, 255);
    drawlink(0, holdp, 0);
    pcl_spring1(0, holdp, 50, 0.05, 0);
    stroke (0, 0, 0);
  }

  float spring = .005;
  float spring_length = 200;
  stroke(0);
  storeCliques();
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    if (!abstraction)
    {
      if (filtrationTechnique == "MinEdges")
      {
        if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])pcl_spring(n1, n2, spring_length, spring, damp);
        if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2]) drawlink(n1, n2, 0);
      }
      if (filtrationTechnique == "KCores")
      {
        if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])pcl_spring(n1, n2, spring_length, spring, damp);
        if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2]) drawlink(n1, n2, 0);
      }
    } else {
      if (main)
      {
        if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
        {
          if (filtrationTechnique == "MinEdges")
          {
            if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])pcl_spring(n1, n2, spring_length, spring, damp);
            if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2]) drawlink(n1, n2, 0);
          }
          if (filtrationTechnique == "KCores")
          {
            if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])pcl_spring(n1, n2, spring_length, spring, damp);
            if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2]) drawlink(n1, n2, 0);
          }
        } else
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] == -1)
          {
            pcl_spring(n1, cliqueIndex[nodeInClique[n2]], spring_length, spring, damp);
            drawlink(n1, cliqueIndex[nodeInClique[n2]], 0);
          } else if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n2] == -1)
          {
            pcl_spring(cliqueIndex[nodeInClique[n1]], n2, spring_length, spring, damp);
            drawlink(cliqueIndex[nodeInClique[n1]], n2, 0);
          } else if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] != -1 && nodeInClique[n2] != -1 && nodeInClique[n1] != nodeInClique[n2])
          {
            pcl_spring(cliqueIndex[nodeInClique[n1]], cliqueIndex[nodeInClique[n2]], spring_length, spring, damp);
            drawlink(cliqueIndex[nodeInClique[n1]], cliqueIndex[nodeInClique[n2]], 0);
          }

          //if (filtrationTechnique == "MinEdges")
          //{
          //  if (nodes1[n1-1] && nodes1[n2-1] && minEdges[n1-1] && minEdges[n2-1]) pcl_spring(n1, n2, sping_length, spring, damp);
          //  if (nodes1[n1-1] && nodes1[n2-1] && minEdges[n1-1] && minEdges[n2-1]) drawlinkClique(n1, n2, 0);
          //}
          //if (filtrationTechnique == "KCores")
          //{
          //  if (nodes1[n1-1] && nodes1[n2-1] && KCore[n1-1] && KCore[n2-1])pcl_spring(n1, n2, sping_length, spring, damp);
          //  if (nodes1[n1-1] && nodes1[n2-1] && KCore[n1-1] && KCore[n2-1]) drawlinkClique(n1, n2, 0);
          //}
        }
      } else
      {
        //pcl_spring(n1, n2, sping_length, spring, damp);
        //drawlink(n1, n2, 0);
      }
    }
  }

  fill (255, 0, 0);
  stroke(0, 255, 0);

  pcl_collisions();
  sys[0].applyForcesMP(2);

  accumulateForces();
  update();

  sys[0].draw();
}

void adjacencyMatrix(boolean main)
{
  stroke(0);
  float buffer = 100;
  if (main)
  {
    if (rightBorder - leftBorder - ( 2 * buffer) < 0) matrixSize = buffer;
    else if (height < rightBorder - leftBorder) matrixSize = height - (buffer);
    else matrixSize = rightBorder - leftBorder - (buffer);
  } else matrixSize = height - (buffer);
  adjacencyMatrix = makeAdjacencyMatrix(filteredTable(table));
  strokeWeight(1);
  fill(0);
  for (int i = 0; i < adjacencyMatrix.length; i++)
  {
    for (int j = 0; j < adjacencyMatrix.length; j++)
    {
      if (mouseX > width/2 + leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i
        && mouseX < width/2 + leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i + ((matrixSize - buffer)/adjacencyMatrix.length)
        && mouseY > buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j
        && mouseY < buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j + ((matrixSize - buffer)/adjacencyMatrix.length))
      {
        fill(200, 100, 100);
      } else fill(0);
      if (clicked && mode == "Filter")
      {
        if (mouseX > width/2 + leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i
          && mouseX < width/2 + leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i + ((matrixSize - buffer)/adjacencyMatrix.length)
          && mouseY > buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j
          && mouseY < buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j + ((matrixSize - buffer)/adjacencyMatrix.length))
        {
          nodes1[i] = false;
          nodes1[j] = false;
        }
      }
      if (highlightEdges[i] || highlightEdges[j]) fill(200, 150, 100);
      if (main)
      {
        if (filtrationTechnique == "MinEdges") if (adjacencyMatrix[i][j] && minEdges[i] && minEdges[j] && nodes1[i] && nodes1[j]) rect(leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i, -height/2 + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j, ((matrixSize - buffer)/adjacencyMatrix.length), ((matrixSize - buffer)/adjacencyMatrix.length));
        if (filtrationTechnique == "KCores") if (adjacencyMatrix[i][j] && KCore[i] && KCore[j] && nodes1[i] && nodes1[j]) rect(leftBorder + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i, -height/2 + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j, ((matrixSize - buffer)/adjacencyMatrix.length), ((matrixSize - buffer)/adjacencyMatrix.length));
      } else
      {
        if (adjacencyMatrix[i][j])
          rect((- matrixSize)/2 + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * i
            , -height/2 + buffer + ((matrixSize - buffer)/adjacencyMatrix.length) * j
            , ((matrixSize - buffer)/adjacencyMatrix.length)
            , ((matrixSize - buffer)/adjacencyMatrix.length));
      }
    }
  }
  fill(0);
}

void arcGraph(boolean main)
{
  int buffer = 100;
  if (main)
  {
    for (int i = 0; i < num_pcls; i++)
    {
      sys[2].pcls[i].p.x = leftBorder + buffer + (((rightBorder - leftBorder) - (2 * buffer))/num_pcls) * i;
      sys[2].pcls[i].p.y = height/4;
      //point(sys[2].pcls[i].p.x, sys[2].pcls[i].p.y);
    }
  } else
  {
    for (int i = 0; i < num_pcls; i++)
    {
      sys[2].pcls[i].p.x = leftBorder + buffer + (((width/2 - leftBorder) - (2 * buffer))/num_pcls) * i;
      sys[2].pcls[i].p.y = height/4;
    }
  }
  sys[2].draw();
  strokeWeight(1);
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    noFill();
    stroke(0, 100);
    float arcHeight = 5 * height/num_nodes1;

    if ((highlightEdges[n1] || highlightEdges[n2]))
    {
      strokeWeight(3);
      stroke(150, 100, 100);
    } else
    {
      strokeWeight(1);
      stroke(0);
    }

    if (main || !main)
    {
      if (!abstraction)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
          {
            curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
              sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
              sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
              sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);
          }
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
              sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
              sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
              sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);
          }
        }
      } else
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
          {
            if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
            {
              curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
                sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);
            } else if (nodeInClique[n1] == -1)
            {
              curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(cliqueIndex[nodeInClique[n2]]-n1)+1)*arcHeight,
                sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-n1)+1)*arcHeight);
            } else if (nodeInClique[n2] == -1)
            {
              curve(sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y + (abs(n2-cliqueIndex[nodeInClique[n1]])+1)*arcHeight,
                sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y + (abs(n2-cliqueIndex[nodeInClique[n1]])+1)*arcHeight);
            } else if (nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
            {
              curve(sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-cliqueIndex[nodeInClique[n1]])+1)*arcHeight,
                sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-cliqueIndex[nodeInClique[n1]])+1)*arcHeight);
            }
          }
        } else if (filtrationTechnique == "KCores")
        {
          //if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          //  curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
          //    sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
          //    sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
          //    sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);

          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2] && nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
            {
              curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
                sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);
            } else if (nodeInClique[n1] == -1)
            {
              curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(cliqueIndex[nodeInClique[n2]]-n1)+1)*arcHeight,
                sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-n1)+1)*arcHeight);
            } else if (nodeInClique[n2] == -1)
            {
              curve(sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y + (abs(n2-cliqueIndex[nodeInClique[n1]])+1)*arcHeight,
                sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
                sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y + (abs(n2-cliqueIndex[nodeInClique[n1]])+1)*arcHeight);
            } else if (nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
            {
              curve(sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-cliqueIndex[nodeInClique[n1]])+1)*arcHeight,
                sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n1]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y,
                sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[2].pcls[cliqueIndex[nodeInClique[n2]]].p.y + (abs(cliqueIndex[nodeInClique[n2]]-cliqueIndex[nodeInClique[n1]])+1)*arcHeight);
            }
          }
        }
      }
    } else
    {
      curve(sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight,
        sys[2].pcls[n1].p.x, sys[2].pcls[n1].p.y,
        sys[2].pcls[n2].p.x, sys[2].pcls[n2].p.y,
        sys[2].pcls[n2].p.x, sys[2].pcls[n1].p.y + (abs(n2-n1)+1)*arcHeight);
    }
  }
  strokeWeight(1);
  stroke(0);
}

void basicRadical(boolean main)
{
  float s = 2*PI/(num_pcls);
  float size = 0;
  if (main)
  {
    if (height > rightBorder - leftBorder) size = rightBorder - leftBorder - 200;
    else size = height - 200;
    if (size < 0) size = 0;
    size /= 2;
    for (int i=0; i<num_pcls; i++)
    {
      sys[3].pcls[i].p.x = -width/2 + (rightBorder - leftBorder)/2 + sin(s*i)*size;
      sys[3].pcls[i].p.y = cos(s*i)*size;
    }
  } else
  {
    size = (height - 200)/2;
    for (int i=0; i<num_pcls; i++)
    {
      sys[3].pcls[i].p.x = sin(s*i)*size;
      sys[3].pcls[i].p.y = cos(s*i)*size;
    }
  }
  sys[3].draw();

  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    stroke(0, 100);

    if ((highlightEdges[n1] || highlightEdges[n2]))
    {
      strokeWeight(3);
      stroke(150, 100, 100);
    } else
    {
      strokeWeight(1);
      stroke(0);
    }

    if (!abstraction)
    {
      if (filtrationTechnique == "MinEdges")
      {
        if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
        {
          line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
        }
      } else if (filtrationTechnique == "KCores")
      {
        if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
        {
          line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
        }
      }
    } else
    {
      if (main || !main)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
          {
            line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
          } else if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] == -1)
          {
            line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[3].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
          } else if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n2] == -1)
          {
            line(sys[3].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[3].pcls[cliqueIndex[nodeInClique[n1]]].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
          } else if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2] && nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
          {
            line(sys[3].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[3].pcls[cliqueIndex[nodeInClique[n1]]].p.y, sys[3].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[3].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
          }
          //if (nodeInClique[n1] == -1)
          //{
          //  pcl_spring(n1, cliqueIndex[nodeInClique[n2]], sping_length, spring, damp);
          //  drawlinkClique(n1, cliqueIndex[nodeInClique[n2]], 0);
          //  //drawlink(n1, n2, 0);a
          //}
          //else if(nodeInClique[n2] == -1)
          //{
          //  pcl_spring(cliqueIndex[nodeInClique[n1]], n2, sping_length, spring, damp);
          //  drawlinkClique(cliqueIndex[nodeInClique[n1]], n2, 0);
          //  //drawlink(n1, n2, 0);
          //}
          //else if(nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
          //{
          //  //pcl_spring(cliqueIndex[nodeInClique[n1]], cliqueIndex[nodeInClique[n2]], sping_length, spring, damp);
          //  drawlinkClique(cliqueIndex[nodeInClique[n1]], cliqueIndex[nodeInClique[n2]], 0);
          //}
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2] && nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
          {
            line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
          }
        }
      } else
      {
        line(sys[3].pcls[n1].p.x, sys[3].pcls[n1].p.y, sys[3].pcls[n2].p.x, sys[3].pcls[n2].p.y);
      }
    }
  }
  strokeWeight(1);
  stroke(0);
}

void curveRadical(boolean main)
{
  float size = 0;
  if (main)
  {
    if (height > rightBorder - leftBorder) size = rightBorder - leftBorder - 200;
    else size = height - 200;
    if (size < 0) size = 0;
    size /= 2;
    float s = 2*PI/(num_pcls);
    for (int i=0; i<num_pcls; i++)
    {
      sys[4].pcls[i].p.x = -width/2 + (rightBorder - leftBorder)/2 + sin(s*i)*size;
      sys[4].pcls[i].p.y = cos(s*i)*size;
      fill(0);
    }
  } else
  {
    size = (height - 200)/2;
    float s = 2*PI/(num_pcls);
    for (int i=0; i<num_pcls; i++)
    {
      sys[4].pcls[i].p.x = sin(s*i)*size;
      sys[4].pcls[i].p.y = cos(s*i)*size;
      fill(0);
    }
  }
  sys[4].draw();

  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    noFill();
    stroke(0, 100);

    if ((highlightEdges[n1] || highlightEdges[n2]))
    {
      strokeWeight(3);
      stroke(150, 100, 100);
    } else
    {
      strokeWeight(1);
      stroke(0);
    }

    if (!abstraction)
    {

      if (main)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (- sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        }
      } else
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (- sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (- sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        }
      }
    } else
    {
      if (main)
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodes1[n1] && nodes1[n2] && minEdges[n1] && minEdges[n2])
          {
            if (nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
            {
              a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
              a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
              b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
              b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
              beginShape();
              curveVertex(a[0], a[1]);
              curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
              curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
              curveVertex(b[0], b[1]);
              endShape();
            } else if (nodeInClique[n1] == -1)
            {
              a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
              a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
              b[0] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x);
              b[1] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
              beginShape();
              curveVertex(a[0], a[1]);
              curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
              curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
              curveVertex(b[0], b[1]);
              endShape();
            } else if (nodeInClique[n2] == -1)
            {
              a[0] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x) ;
              a[1] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
              b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
              b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
              beginShape();
              curveVertex(a[0], a[1]);
              curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
              curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
              curveVertex(b[0], b[1]);
              endShape();
            } else if (nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
            {
              a[0] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x) ;
              a[1] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
              b[0] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x);
              b[1] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
              beginShape();
              curveVertex(a[0], a[1]);
              curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
              curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
              curveVertex(b[0], b[1]);
              endShape();
            }
            //a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
            //a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            //b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
            //b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            //beginShape();
            //curveVertex(a[0], a[1]);
            //curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            //curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            //curveVertex(b[0], b[1]);
            //endShape();
          }
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        }
      } else
      {
        if (filtrationTechnique == "MinEdges")
        {
          if (nodeInClique[n1] == -1 && nodeInClique[n2] == -1)
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          } else if (nodeInClique[n1] == -1)
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x);
            b[1] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          } else if (nodeInClique[n2] == -1)
          {
            a[0] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x) ;
            a[1] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          } else if (nodeInClique[n1] != -1 && nodeInClique[n2] != -1)
          {
            a[0] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x - 2.5 * (-width/2 + (rightBorder - leftBorder)/2- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x) ;
            a[1] = sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
            b[0] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x - 2.5 * (-width/2 + + (rightBorder - leftBorder)/2 - sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x);
            b[1] = sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y - 2.5 * (- sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n1]]].p.y);
            curveVertex(sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.x, sys[4].pcls[cliqueIndex[nodeInClique[n2]]].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        } else if (filtrationTechnique == "KCores")
        {
          if (nodes1[n1] && nodes1[n2] && KCore[n1] && KCore[n2])
          {
            a[0] = sys[4].pcls[n1].p.x - 2.5 * (- sys[4].pcls[n1].p.x) ;
            a[1] = sys[4].pcls[n1].p.y - 2.5 * (- sys[4].pcls[n1].p.y);
            b[0] = sys[4].pcls[n2].p.x - 2.5 * (- sys[4].pcls[n2].p.x);
            b[1] = sys[4].pcls[n2].p.y - 2.5 * (- sys[4].pcls[n2].p.y);
            beginShape();
            curveVertex(a[0], a[1]);
            curveVertex(sys[4].pcls[n1].p.x, sys[4].pcls[n1].p.y);
            curveVertex(sys[4].pcls[n2].p.x, sys[4].pcls[n2].p.y);
            curveVertex(b[0], b[1]);
            endShape();
          }
        }
      }
    }
  }

  strokeWeight(1);
  stroke(0);
}

Table filteredTable(Table tbl)
{
  Table returnTable = new Table();
  for (TableRow row : tbl.rows()) {
    int n1 = row.getInt(0);
    int n2 = row.getInt(1);
    if (filtrationTechnique == "MinEdges")if (minEdges[n1-1] && minEdges[n2-1] && nodes1[n1-1] && nodes1[n2-1]) returnTable.addRow(row);
    if (filtrationTechnique == "KCores")if (KCore[n1-1] && KCore[n2-1] && nodes1[n1-1] && nodes1[n2-1]) returnTable.addRow(row);
  }
  return returnTable;
}

boolean[][] makeAdjacencyMatrix(Table tbl)
{
  adjacencyMatrix = new boolean[num_pcls][num_pcls];
  matrixHighlight = new boolean[num_pcls][num_pcls];
  for (TableRow row : tbl.rows()) {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    adjacencyMatrix[n1][n2] = true;
    adjacencyMatrix[n2][n1] = true;
  }
  return adjacencyMatrix;
}

void mouseWheel(MouseEvent event) {
  scroll -= 10 * event.getCount();
  println(scroll);
}

void loadCliques()
{
  maxCliqueSize = int(loadStrings(FILE_NAME + "\\" + FILE_NAME + "_max_clique_size.txt")[0]);
  allCliques = new ArrayList[int(loadStrings(FILE_NAME + "\\" + FILE_NAME + "_max_clique_size.txt")[0])-2][3];
  allEdges = new int[int(loadStrings(FILE_NAME + "\\" + FILE_NAME + "_max_clique_size.txt")[0])-2][num_nodes];
  for (int i = 3; i < allCliques.length + 3; i++)
  {
    allCliques[i-3][0] = new ArrayList<Table>();
    String folder = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed" + "\\" + FILE_NAME + "_min_clique" + i;
    int x = 3;
    while (true)
    {
      String toLookFor = FILE_NAME + "_cliques_processed"+x+".csv";
      Table cliqueTable = loadTable(folder+"\\"+toLookFor);
      if (cliqueTable != null)allCliques[i-3][0].add(cliqueTable);
      else break;
      x++;
    }
  }
  for (int i = 3; i < allCliques.length + 3; i++)
  {
    allCliques[i-3][1] = new ArrayList<Table>();
    String folder = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed" + "\\" + FILE_NAME + "_min_clique" + i + "_betweenness_centrality";
    int x = 3;
    while (true)
    {
      String toLookFor = FILE_NAME + "_cliques_processed"+x+".csv";
      Table cliqueTable = loadTable(folder+"\\"+toLookFor);
      if (cliqueTable != null)allCliques[i-3][1].add(cliqueTable);
      else break;
      x++;
    }
  }
  for (int i = 3; i < allCliques.length + 3; i++)
  {
    allCliques[i-3][2] = new ArrayList<Table>();
    String folder = FILE_NAME + "\\" + FILE_NAME + "_cliques_processed" + "\\" + FILE_NAME + "_min_clique" + i + "_closeness_centrality";
    int x = 3;
    while (true)
    {
      String toLookFor = FILE_NAME + "_cliques_processed"+x+".csv";
      Table cliqueTable = loadTable(folder+"\\"+toLookFor);
      if (cliqueTable != null)allCliques[i-3][2].add(cliqueTable);
      else break;
      x++;
    }
  }
  Collections.reverse(allCliques[maxCliqueSize-3][cliqueSet]);
}

void storeCliques()
{
  int holder;
  totalCliques = 0;
  if (currentValue[cliqueSet + 2] == 0) holder = maxCliqueSize;
  else holder = currentValue[cliqueSet + 2];
  for (int i = 0; i < allCliques[holder-3][cliqueSet].size(); i++)
  {
    for (TableRow row : allCliques[holder-3][cliqueSet].get(i).rows())
    {
      totalCliques++;
    }
  }

  int x=3;
  int counter = 0;
  boolean isNewCliques = lastHolder == holder;
  if ( !isNewCliques)
  {
    cliqueIndex = new int[totalCliques];
    edgesPerClique = new int[totalCliques];
    for (int i = 0; i < allCliques[holder-3][cliqueSet].size(); i++)
    {
      Table currentClique = allCliques[holder-3][cliqueSet].get(i);
      for (TableRow row : currentClique.rows())
      {
        for (int j = 0; j < row.getColumnCount(); j++)
        {
          nodeInClique[row.getInt(j)] = counter;
        }
        edgesPerClique[counter] = (currentValue[cliqueSet+2] - x) + 3;
        cliqueIndex[counter++] = row.getInt(0);
      }
      x++;
    }
  }
  lastHolder = holder;
  //for (int i = 0; i < edgesPerClique.length; i++) println(i + ", " + edgesPerClique[i]);
  //println("------------");
}
