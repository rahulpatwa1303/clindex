import { useState, useEffect } from 'react'
import axios from 'axios'

const API_URL = "http://localhost:8000"; // Adjust if needed

function App() {
  const [scans, setScans] = useState([]);
  const [selectedScan, setSelectedScan] = useState(null);

  // 1. Fetch Pending Scans
  useEffect(() => {
    fetchScans();
  }, []);

  const fetchScans = async () => {
    try {
      const res = await axios.get(`${API_URL}/scans/pending`);
      setScans(res.data);
    } catch (err) {
      console.error("Error fetching scans:", err);
    }
  };

  // 2. Save & Verify
  const handleSave = async (updatedData) => {
    try {
      await axios.put(`${API_URL}/scan/${selectedScan.id}`, {
        extracted_data: updatedData
      });
      alert("Verified & Saved!");
      setSelectedScan(null); // Close editor
      fetchScans(); // Refresh list
    } catch (err) {
      alert("Error saving: " + err.message);
    }
  };

  return (
    <div style={{ padding: 20, fontFamily: 'sans-serif' }}>
      <h1>🏥 Admin Verification Dashboard</h1>
      
      {/* LIST VIEW */}
      {!selectedScan && (
        <div>
          <h3>Pending Reviews ({scans.length})</h3>
          <table border="1" cellPadding="10" style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th>Date Uploaded</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {scans.map(scan => (
                <tr key={scan.id}>
                  <td>{new Date(scan.created_at).toLocaleString()}</td>
                  <td style={{ color: 'red' }}>Pending Review</td>
                  <td>
                    <button onClick={() => setSelectedScan(scan)}>
                      Review Now
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* EDITOR VIEW */}
      {selectedScan && (
        <Editor 
          scan={selectedScan} 
          onSave={handleSave} 
          onCancel={() => setSelectedScan(null)} 
        />
      )}
    </div>
  )
}

// Simple Editor Component
function Editor({ scan, onSave, onCancel }) {
  // Deep copy data to edit
  const [data, setData] = useState(scan.extracted_data);

  const updateRecord = (index, field, value) => {
    const newRecords = [...data.records];
    newRecords[index][field] = value;
    setData({ ...data, records: newRecords });
  };

  return (
    <div style={{ display: 'flex', gap: '20px', height: '80vh' }}>
      
      {/* LEFT: IMAGE */}
      <div style={{ flex: 1, border: '1px solid #ccc', overflow: 'auto' }}>
        <img src={scan.image_url} alt="Scan" style={{ width: '100%' }} />
      </div>

      {/* RIGHT: FORM */}
      <div style={{ flex: 1, overflow: 'auto', padding: 10 }}>
        <button onClick={onCancel} style={{ marginRight: 10 }}>Cancel</button>
        <button onClick={() => onSave(data)} style={{ backgroundColor: 'green', color: 'white' }}>
          VERIFY & SAVE
        </button>
        
        <h3>Records</h3>
        {data.records?.map((record, idx) => (
          <div key={idx} style={{ border: '1px solid #ddd', padding: 10, marginBottom: 10, borderRadius: 5 }}>
            <strong>#{idx + 1}</strong>
            <div style={{ marginBottom: 5 }}>
              <label>Name: </label>
              <input 
                value={record.patient_name || ''} 
                onChange={(e) => updateRecord(idx, 'patient_name', e.target.value)}
              />
            </div>
            <div style={{ marginBottom: 5 }}>
              <label>Treatment: </label>
              <input 
                value={record.treatment || ''} 
                onChange={(e) => updateRecord(idx, 'treatment', e.target.value)}
              />
            </div>
            <div style={{ marginBottom: 5 }}>
              <label>Amount: </label>
              <input 
                type="number"
                value={record.amount || 0} 
                onChange={(e) => updateRecord(idx, 'amount', Number(e.target.value))}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default App