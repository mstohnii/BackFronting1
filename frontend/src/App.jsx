import React, { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

// Configure axios base URL - this will be handled by nginx proxy
const api = axios.create({
  baseURL: '/api'
})

function App() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [newItem, setNewItem] = useState({ name: '', description: '' })
  const [backendStatus, setBackendStatus] = useState(null)

  // Check backend health
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await api.get('/health')
        setBackendStatus(response.data.message)
      } catch (err) {
        setBackendStatus('Backend unreachable')
      }
    }
    checkHealth()
  }, [])

  // Fetch items from backend
  useEffect(() => {
    const fetchItems = async () => {
      try {
        setLoading(true)
        const response = await api.get('/items')
        setItems(response.data.data)
        setError(null)
      } catch (err) {
        setError('Failed to fetch items')
        console.error('Error fetching items:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchItems()
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!newItem.name || !newItem.description) {
      alert('Please fill in both fields')
      return
    }

    try {
      const response = await api.post('/items', newItem)
      setItems([...items, response.data.data])
      setNewItem({ name: '', description: '' })
      setError(null)
    } catch (err) {
      setError('Failed to add item')
      console.error('Error adding item:', err)
    }
  }

  if (loading) {
    return (
      <div className="app">
        <div className="container">
          <div className="loading">Loading...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="app">
      <div className="container">
        <header className="header">
          <h1>🚀 Full Stack App</h1>
          <div className={`status ${backendStatus?.includes('running') ? 'success' : 'error'}`}>
            Backend: {backendStatus}
          </div>
        </header>

        {error && <div className="error">{error}</div>}

        <div className="add-item-form">
          <h2>Add New Item</h2>
          <form onSubmit={handleSubmit}>
            <input
              type="text"
              placeholder="Item name"
              value={newItem.name}
              onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
            />
            <input
              type="text"
              placeholder="Item description"
              value={newItem.description}
              onChange={(e) => setNewItem({ ...newItem, description: e.target.value })}
            />
            <button type="submit">Add Item</button>
          </form>
        </div>

        <div className="items-section">
          <h2>Items from Backend</h2>
          <div className="items-grid">
            {items.map(item => (
              <div key={item.id} className="item-card">
                <h3>{item.name}</h3>
                <p>{item.description}</p>
                <span className="item-id">ID: {item.id}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
