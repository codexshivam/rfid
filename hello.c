#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <WiFiClientSecure.h>

// --- Configuration ---
const char* ssid = "ALHN-76A5";
const char* password = "T5eJdezqc5";

// Appwrite Endpoint
String endpoint = "https://sgp.cloud.appwrite.io/v1/databases/UniVault_DB/collections/sessions/documents/69dfdb5b00158bbb62bb";
String projectID = "rfid-app";
String apiKey = "standard_787d3dcf07b1cab16d9251b7abca9e7f287599dbca638c262786a3bc416aeffdf55036b6aacbcf67ce7d3dbf0d307865996e85a76ded0ef6cda6bca77e2332460e73311ef67b71bd086ea444486d65077e2267c1b7c6d1384badcd2e8a3c8dd857d49764c9fa117341e50211e3eabaa56d2278951e615295ddcb986bedcf874b";

// Hardware Pins
#define SS_PIN  5
#define RST_PIN 22
MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  
  // WiFi Connection
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected! Yadav Ji, System Ready.");

  SPI.begin();
  rfid.PCD_Init();
  Serial.println("RFID Reader Initialized.");
}

void loop() {
  // Check for new card
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;

  // Read UID
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uid += String(rfid.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  Serial.println("\n--- Card Tapped: " + uid + " ---");

  toggleState(uid);

  // Stop reading current card
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  
  delay(3000); // 3-second debounce
}

void toggleState(String cardUid) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure(); // Important for Cloud SSL
    HTTPClient http;

    // --- STEP 1: GET CURRENT STATUS ---
    Serial.println("Fetching current status from Appwrite...");
    http.begin(client, endpoint);
    http.addHeader("X-Appwrite-Project", projectID);
    http.addHeader("X-Appwrite-Key", apiKey);
    
    int getCode = http.GET();
    Serial.print("GET Response Code: ");
    Serial.println(getCode);

    bool currentStatus = false;
    if (getCode == 200) {
      String response = http.getString();
      if (response.indexOf("\"is_active\":true") != -1) {
        currentStatus = true;
      }
      Serial.print("Current State in DB: ");
      Serial.println(currentStatus ? "ACTIVE" : "INACTIVE");
    } else {
      Serial.println("Failed to fetch status. Check your Database/Collection/Document IDs.");
      http.end();
      return; 
    }
    http.end();

    // --- STEP 2: PATCH NEW STATUS ---
    bool nextStatus = !currentStatus;
    Serial.println("Updating status...");
    
    http.begin(client, endpoint);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Appwrite-Project", projectID);
    http.addHeader("X-Appwrite-Key", apiKey);

    String jsonBody = "{\"data\": {\"is_active\": " + String(nextStatus ? "true" : "false") + ", \"current_uid\": \"" + cardUid + "\"}}";

    int patchCode = http.PATCH(jsonBody);
    Serial.print("PATCH Response Code: ");
    Serial.println(patchCode);

    if (patchCode == 200 || patchCode == 204) {
      Serial.println("SUCCESS: Yadav Ji, System Update Ho Gaya!");
      Serial.print("New State: ");
      Serial.println(nextStatus ? "LOGGED IN" : "LOGGED OUT");
    } else {
      Serial.print("ERROR: PATCH Failed. Code: ");
      Serial.println(patchCode);
      String errorResponse = http.getString();
      Serial.println("Server Message: " + errorResponse);
    }
    http.end();
  } else {
    Serial.println("WiFi Disconnected! Cannot update Appwrite.");
  }
}