// Test MQTT parsing logic locally
const testPayload = {
  "gps": {
    "lat": -5.349413,
    "lon": 105.2675,
    "alt": 101.6,
    "sat": 5
  },
  "soil": {
    "temperature": 25,
    "humidity": 25.9,
    "ec": 344,
    "ph": 7,
    "n": 33,
    "p": 123,
    "k": 116
  }
};

const latestSensorData = {
    N: 0.0,
    P: 0.0,
    K: 0.0,
    temperature: 0.0,
    humidity: 0.0,
    pH: 0.0,
    ec: 0.0,
    lat: 0.0,
    lon: 0.0,
    alt: 0.0,
    sat: 0,
    timestamp: Date.now() / 1000,
    status_mqtt: 'TESTING'
};

// Simulate parsing
const data = testPayload;
let soilData = data.soil || data;

// Parse GPS
if (data.gps) {
    const gpsData = data.gps;
    latestSensorData.lat = parseFloat(gpsData.lat || gpsData.latitude) || 0.0;
    latestSensorData.lon = parseFloat(gpsData.lon || gpsData.longitude) || 0.0;
    latestSensorData.alt = parseFloat(gpsData.alt || gpsData.altitude) || 0.0;
    latestSensorData.sat = parseInt(gpsData.sat || gpsData.satellites) || 0;
    console.log(`GPS updated - Lat: ${latestSensorData.lat}, Lon: ${latestSensorData.lon}`);
}

// Parse soil data - support both lowercase and uppercase
if (soilData) {
    // Temperature
    latestSensorData.temperature = parseFloat(soilData.temperature || soilData.Temperature || soilData.temp) || 0.0;
    
    // Humidity
    latestSensorData.humidity = parseFloat(soilData.humidity || soilData.Humidity) || 0.0;
    
    // N, P, K (NPK nutrients)
    latestSensorData.N = parseFloat(soilData.n || soilData.N) || 0.0;
    latestSensorData.P = parseFloat(soilData.p || soilData.P) || 0.0;
    latestSensorData.K = parseFloat(soilData.k || soilData.K) || 0.0;
    
    // pH
    latestSensorData.pH = parseFloat(soilData.ph || soilData.pH || soilData.Ph) || 0.0;
    
    // EC (Electrical Conductivity)
    latestSensorData.ec = parseFloat(soilData.ec || soilData.EC || soilData.Ec) || 0.0;
    
    console.log(`Soil parsed - N:${latestSensorData.N}, P:${latestSensorData.P}, K:${latestSensorData.K}, pH:${latestSensorData.pH}, EC:${latestSensorData.ec}`);
}

console.log('\n=== FINAL RESULT ===');
console.log(JSON.stringify(latestSensorData, null, 2));
