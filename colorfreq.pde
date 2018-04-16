import processing.sound.*;
import themidibus.*;
import java.util.concurrent.*;

ConcurrentHashMap<Integer, Integer> activeNotes;
ConcurrentHashMap<Integer, TriOsc> activeOscillators;
float MAX_AMPLITUDE = 0.2;
float COLOR_CORRECTION_TO_MAX_AMPLITUDE = 1.0 / MAX_AMPLITUDE;

MidiBus myBus;

void setup() {
  size(400, 400);
  //fullScreen();
  background(0);
  colorMode(HSB, 1.0);
  frameRate(24);

  MidiBus.list();
  myBus = new MidiBus(this, "KEYBOARD", "Real Time Sequencer");
  activeNotes = new ConcurrentHashMap(16, 0.9, 1);
  activeOscillators = new ConcurrentHashMap(16, 0.9, 1);
  setupOscs();
}

void draw() {
  background(0.0, 0.0, 0.0, 0.0001);
  float[] intensities = new float[12];
  synchronized(activeNotes) {
    int activeNotesCount = activeNotes.size();
    for (int i = 0; i < 12; i++) {
      // 5 because we start from F
      for (int j = i + 5; j < 127; j += 12) {
        if (activeNotes.containsKey(j)) {
          intensities[i] += getAmpFromVelocity(activeNotes.get(j), 1) * COLOR_CORRECTION_TO_MAX_AMPLITUDE;
        }
      }
    }
  }

  for (int i = 0; i < width; i++) {
    float pos = float(i) / width;
    int pitchClassFromF = int(lerp(0.0, 11.0, pos));
    float alpha = intensities[pitchClassFromF];
    stroke(pos, 1.0, 1.0, alpha);
    line(i, 0, i, height);
  }
}

void setupOscs() {
  for (int i = 0; i < 128; i++) {
    TriOsc osc = new TriOsc(this);
    float freq = getFreqFromPitch(i);
    osc.play(freq, 0.0);
    activeOscillators.put(i, osc);
  }
}

void syncOscs() {
  printNotes();
  int activeNotesCount = activeNotes.size();
  for (java.util.Map.Entry<Integer, Integer> entry : activeNotes.entrySet()) {
    Integer pitch = entry.getKey();
    Integer velocity = entry.getValue();
    float freq = getFreqFromPitch(pitch);
    float amp = getAmpFromVelocity(velocity, activeNotesCount);
    float pan = getPanFromPitch(pitch);

    TriOsc osc = activeOscillators.get(pitch);
    println(amp);
    osc.set(freq, amp, 0.0, 0.0);
  }
}

void printNotes() {
  for (java.util.Map.Entry<Integer, Integer> entry : activeNotes.entrySet()) {
    Integer note = entry.getKey();
    Integer velocity = entry.getValue();
    println(str(note) + ":" + str(velocity));
  }
}

void noteOn(int channel, int pitch, int velocity) {
  //println(pitch, velocity);
  activeNotes.put(pitch, velocity);
  syncOscs();
}

void noteOff(int channel, int pitch, int velocity) {
  //println(pitch, velocity, "Off");
  activeNotes.put(pitch, 0);
  syncOscs();
}

float getFreqFromPitch(int pitch) {
  return pow(2, float(pitch - 69)/12.0) * 440.0;
}

float getPanFromPitch(int pitch) {
  return float(pitch) / 128.0;
}

float getAmpFromVelocity(int velocity, int activeNotesCount) {
  float max_amp_per_osc = MAX_AMPLITUDE / activeNotesCount;
  return max_amp_per_osc * (float(velocity)/128.0);
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
