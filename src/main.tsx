import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';
import './visual-upgrade.css';
import './ludo-dice-upgrade.css';
import './pool.css';

createRoot(document.getElementById('root')!).render(<React.StrictMode><App /></React.StrictMode>);
