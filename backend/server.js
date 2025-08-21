import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import moment from 'moment';
import PDFDocument from 'pdfkit';
import fs from 'fs';  
import path from 'path';
import { fileURLToPath } from 'url';

import User from './models/user.js';
import Patient from './models/patient.js';
import Treatment, { seedTreatments } from './models/treatment.js'; // Import Treatment model
import Appointment from './models/appointment.js';
import Expense from './models/expense.js';
import LabWarranty from './models/Lab_Warranty.js'; // Import LabWarranty model

// Polyfill __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Registration endpoint
app.post('/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ message: 'Email and password required' });

  const existing = await User.findOne({ email });
  if (existing)
    return res.status(400).json({ message: 'User already exists' });

  const hashed = await bcrypt.hash(password, 10);
  const user = new User({ email, password: hashed });
  await user.save();
  res.status(201).json({ message: 'User registered' });
});

// Add user
app.post('/users', async (req, res) => {
  const { email, password, capabilityLevel } = req.body;
  if (!email || !password || capabilityLevel == null)
    return res.status(400).json({ message: 'Missing fields' });

  const existing = await User.findOne({ email });
  if (existing)
    return res.status(400).json({ message: 'User already exists' });

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = await User.create({
    email,
    password: hashedPassword,
    capabilityLevel: Number(capabilityLevel), // <-- ensure it's a number
  });
  res.status(201).json(user);
});

// List users
app.get('/users', async (req, res) => {
  const users = await User.find({});
  res.json(users);
});

// Update user
app.put('/users/:id', async (req, res) => {
  const { email, password, capabilityLevel } = req.body;
  const update = { email, capabilityLevel };
  if (password) update.password = await bcrypt.hash(password, 10);
  const user = await User.findByIdAndUpdate(req.params.id, update, { new: true });
  res.json(user);
});

// Delete user
app.delete('/users/:id', async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ success: true });
});

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ message: 'Invalid credentials' });
  const valid = await bcrypt.compare(password, user.password);
  if (!valid) return res.status(400).json({ message: 'Invalid credentials' });

  // Return only needed fields
  res.json({
    email: user.email,
    capabilityLevel: user.capabilityLevel ?? 1, // <-- This is what your Flutter app uses
  });
});

// Register patient (assigns unique _id automatically)
app.post('/patients', async (req, res) => {
  try {
    // Find the highest patientId in the collection
    const lastPatient = await Patient.findOne().sort({ patientId: -1 });
    const nextPatientId = lastPatient && lastPatient.patientId
      ? lastPatient.patientId + 1
      : 100001;

    const { name, age, gender, address, phone, hasComplication, description, branch } = req.body;
    const patient = new Patient({
      patientId: nextPatientId,
      name,
      age,
      gender,
      address,
      phone,
      hasComplication,
      description: hasComplication ? description : '',
      branch, // Save branch
    });
    await patient.save();
    res.status(201).json({ message: 'Patient registered', patientId: nextPatientId });
  } catch (err) {
    res.status(400).json({ message: err.message || 'Registration failed' });
  }
});

// Search by phone
app.get('/patients/phone/:phone', async (req, res) => {
  try {
    const patient = await Patient.findOne({ phone: req.params.phone });
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    res.json(patient);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Search by patientId
app.get('/patients/patientid/:patientId', async (req, res) => {
  try {
    const patient = await Patient.findOne({ patientId: Number(req.params.patientId) });
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    res.json(patient);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update by patientId
app.put('/patients/patientid/:patientId', async (req, res) => {
  try {
    const updated = await Patient.findOneAndUpdate(
      { patientId: Number(req.params.patientId) },
      { $set: { treatments: req.body.treatments } },
      { new: true }
    );
    if (!updated) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    res.json({ message: 'Treatment updated', patient: updated, patientId: updated.patientId });
  } catch (err) {
    res.status(400).json({ message: err.message || 'Update failed' });
  }
});

// Patient search by name, phone, or patientId using Mongoose
app.get('/patients', async (req, res) => {
  const { query, date, month, year } = req.query;
  let filter = {};

  // Search by name, phone, or patientId
  if (query) {
    filter.$or = [
      { name: { $regex: query, $options: 'i' } },
    ];
    if (!isNaN(Number(query))) {
      filter.$or.push({ patientId: Number(query) });
      filter.$or.push({ phone: Number(query) });
    }
  }

  // Date/month/year filter (unchanged)
  if (date) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);
    filter.createdAt = { $gte: start, $lte: end };
  } else if (month && year) {
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);
    filter.createdAt = { $gte: start, $lte: end };
  } else if (year) {
    const start = new Date(year, 0, 1);
    const end = new Date(year, 11, 31, 23, 59, 59, 999);
    filter.createdAt = { $gte: start, $lte: end };
  }

  // Always select patientId, name, phone, and other needed fields
  const patients = await Patient.find(filter).select('patientId name age gender address phone treatments payments description branch chiefComplaints hasComplication description');
  res.json(patients);
});

// Add payment (with mode and transactionId)
app.post('/patients/:id/payments', async (req, res) => {
  function generateInvoiceNo() {
    const prefix = 'ADC';
    const now = new Date();
    const datePart = `${now.getFullYear()}${(now.getMonth()+1).toString().padStart(2,'0')}${now.getDate().toString().padStart(2,'0')}`;
    const randomPart = Math.floor(100000 + Math.random() * 900000); // 6 digits
    return `${prefix}${datePart}${randomPart}`;
  }

  const { amount, date, mode, transactionId } = req.body;
  const patient = await Patient.findOne({ patientId: Number(req.params.id) });
  if (!patient) return res.status(404).send('Patient not found');

  const invoiceNo = generateInvoiceNo();

  // Add the new payment with invoiceNo
  patient.payments.push({
    amount,
    date,
    mode,
    transactionId,
    invoiceNo, // Store the generated invoice number
  });

  await patient.save();
  res.json({ success: true, invoiceNo }); // Optionally return the invoice number
});


// Update treatment estimate by index
app.put('/patients/:id/treatments/:treatmentIdx', async (req, res) => {
  const { estimate } = req.body;
  const patient = await Patient.findOne({ patientId: req.params.id });
  if (!patient) return res.status(404).send('Patient not found');
  const idx = parseInt(req.params.treatmentIdx, 10);
  if (patient.treatments[idx]) {
    patient.treatments[idx].estimate = estimate;
    await patient.save();
    res.json({ success: true ,patientId: patient.patientId });
  } else {
    res.status(404).send('Treatment not found');
  }
});

// Update payment amount by index
app.put('/patients/:id/payments/:paymentIdx', async (req, res) => {
  const { amount } = req.body;
  const patient = await Patient.findOne({ patientId: req.params.id });
  if (!patient) return res.status(404).send('Patient not found');
  const idx = parseInt(req.params.paymentIdx, 10);
  if (patient.payments[idx]) {
    patient.payments[idx].amount = amount;
    await patient.save();
    res.json({ success: true });
  } else {
    res.status(404).send('Payment not found');
  }
});

// Dashboard summary for charts
app.get('/dashboard-summary', async (req, res) => {
  let { from, to, month, year, date } = req.query;
  const { branch } = req.query;
  let start, end;

  // Date range calculation
  if (date) {
    start = new Date(date);
    start.setHours(0, 0, 0, 0);
    end = new Date(date);
    end.setHours(23, 59, 59, 999);
  } else if (from && to) {
    start = new Date(from);
    start.setHours(0,0,0,0);
    end = new Date(to);
    end.setHours(23,59,59,999);
  } else if (month && year) {
    start = new Date(year, month - 1, 1);
    end = new Date(year, month, 0, 23, 59, 59, 999);
  } else if (year) {
    start = new Date(year, 0, 1);
    end = new Date(year, 11, 31, 23, 59, 59, 999);
  } else {
    start = new Date();
    start.setHours(0,0,0,0);
    end = new Date();
    end.setHours(23,59,59,999);
  }

  // Build patient query
  let patientQuery = { createdAt: { $gte: start, $lte: end } };
  if (branch && branch !== 'All Branches') {
    patientQuery.branch = branch;
  }

  // Patients registered in the period
  const patients = await Patient.find(patientQuery);

  // Registrations count
  const registrations = patients.length;

  // Revenue and pipeline
  let totalPaid = 0, totalEstimate = 0;
  patients.forEach(p => {
    if (Array.isArray(p.payments)) {
      totalPaid += p.payments.reduce((sum, pay) => sum + (Number(pay.amount) || 0), 0);
    }
    if (Array.isArray(p.treatments)) {
      totalEstimate += p.treatments.reduce((sum, t) => sum + (Number(t.estimate) || 0), 0);
    }
  });

  // Payment mode summary (Cash vs Online)
  let cashTotal = 0;
  let onlineTotal = 0;
  patients.forEach(p => {
    if (Array.isArray(p.payments)) {
      p.payments.forEach(pay => {
        const payDate = new Date(pay.date);
        if (payDate >= start && payDate <= end) {
          if (pay.mode === 'Cash') cashTotal += Number(pay.amount) || 0;
          if (pay.mode === 'Online') onlineTotal += Number(pay.amount) || 0;
        }
      });
    }
  });

  // Pipeline is the sum of all treatment estimates
  const pipeline = totalEstimate;

  res.json({
    registrations,
    totalPaid,
    totalEstimate,
    pipeline,
    cashTotal,
    onlineTotal
  });
});

app.post('/appointments', async (req, res) => {
  const { patientId, name, phone, age, address, appointmentDate, appointmentTime, treatment } = req.body;
  if (!patientId || !name || !phone || !age || !address || !appointmentDate || !appointmentTime || !treatment) {
    return res.status(400).json({ error: 'Missing fields' });
  }
  await Appointment.create({
    patientId,
    name,
    phone,
    age,
    address,
    appointmentDate,
    appointmentTime,
    treatment
  });
  res.status(201).json({ message: 'Appointment scheduled' });
});

// GET /appointments
app.get('/appointments', async (req, res) => {
  const { date } = req.query;
  let filter = {};
  if (date) {
    filter.appointmentDate = date;
  }
  const appointments = await Appointment.find(filter);
  res.json(appointments);
});

app.post('/patients/:id/treatments', async (req, res) => {
  const { chiefComplaints, treatments } = req.body;
  const patient = await Patient.findOne({ patientId: req.params.id });
  if (!patient) return res.status(404).send('Patient not found');
  patient.chiefComplaints = chiefComplaints;
  patient.treatments = treatments.filter(t => t.type && (t.description || t.estimate));
  await patient.save();
  res.json({ success: true });
});

// Register the endpoint
app.get('/treatments', async (req, res) => {
  const treatments = await Treatment.find({});
  res.json(treatments);
});

// (Optional) Seed treatments once on startup
// await seedTreatments();



// Example for fetchRegistrationsData
// (Dart/Flutter code removed as it does not belong in a JavaScript file)

app.get('/patients/:id', async (req, res) => {
  const patientId = parseInt(req.params.id, 10);
  const patient = await Patient.findOne({ patientId });
  if (!patient) return res.status(404).json({ message: 'Patient not found' });
  res.json(patient);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Add new treatment to a patient (append, don't replace)
app.post('/patients/:id/add-treatment', async (req, res) => {
  try {
    const patientId = req.params.id;
    const { chiefComplaints, treatments } = req.body;

    // Add date to each treatment if not present
    const treatmentsWithDate = treatments.map(t => ({
      ...t,
      date: t.date || new Date().toISOString(),
    }));

    // Append new treatments to the treatments array
    const patient = await Patient.findOneAndUpdate(
      { patientId: Number(patientId) },
      {
        $push: { treatments: { $each: treatmentsWithDate } },
        $set: { chiefComplaints }, // Optionally update chief complaints
      },
      { new: true }
    );

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found.' });
    }

    res.json({ message: 'Treatment(s) added successfully!', patient });
  } catch (err) {
    res.status(500).json({ message: 'Error adding treatment.', error: err.message });
  }
});

// Add a new expense
app.post('/expenses', async (req, res) => {
  try {
    const { txnId, branch, type, description, amount, paymentMode, date } = req.body;
    const expense = new Expense({
      txnId,
      branch, // <-- add this
      type,
      description,
      amount,
      paymentMode,
      date,
    });
    await expense.save();
    res.status(201).json({ message: 'Expense added successfully', expense });
  } catch (err) {
    res.status(500).json({ message: 'Error adding expense', error: err.message });
  }
});

// (Optional) Get all expenses
app.get('/expenses', async (req, res) => {
  try {
    let filter = {};
    if (req.query.branch) filter.branch = req.query.branch;
    if (req.query.date) {
      const date = new Date(req.query.date);
      const next = new Date(date);
      next.setDate(date.getDate() + 1);
      filter.date = { $gte: date, $lt: next };
    } else if (req.query.month && req.query.year) {
      const year = parseInt(req.query.year);
      const month = parseInt(req.query.month) - 1;
      const start = new Date(year, month, 1);
      const end = new Date(year, month + 1, 0, 23, 59, 59, 999);
      filter.date = { $gte: start, $lte: end };
    } else if (req.query.year) {
      const year = parseInt(req.query.year);
      const start = new Date(year, 0, 1);
      const end = new Date(year, 11, 31, 23, 59, 59, 999);
      filter.date = { $gte: start, $lte: end };
    }
    const expenses = await Expense.find(filter).sort({ date: -1 });
    res.json(expenses);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching expenses', error: err.message });
  }
});

app.get('/expense-summary', async (req, res) => {
  try {
    const match = {};
    // Branch filter
    if (req.query.branch && req.query.branch !== 'All Branches') {
      match.branch = req.query.branch;
    }
    // Date filter
    if (req.query.date) {
      const date = new Date(req.query.date);
      const next = new Date(date);
      next.setDate(date.getDate() + 1);
      match.date = { $gte: date, $lt: next };
    }
    // Month & Year filter
    else if (req.query.month && req.query.year) {
      const year = parseInt(req.query.year);
      const month = parseInt(req.query.month) - 1;
      const start = new Date(year, month, 1);
      const end = new Date(year, month + 1, 0, 23, 59, 59, 999);
      match.date = { $gte: start, $lte: end };
    }
    // Year filter only
    else if (req.query.year) {
      const year = parseInt(req.query.year);
      const start = new Date(year, 0, 1);
      const end = new Date(year, 11, 31, 23, 59, 59, 999);
      match.date = { $gte: start, $lte: end };
    }

    const summary = await Expense.aggregate([
      { $match: match },
      { $group: { _id: '$type', total: { $sum: '$amount' } } },
    ]);
    const result = {};
    summary.forEach(item => {
      result[item._id] = item.total;
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching expense summary', error: err.message });
  }
});

app.get('/revenue-expense-summary', async (req, res) => {
  try {
    // Date/branch filter for patients
    const { branch, date, month, year } = req.query;
    let start, end;

    if (date) {
      start = new Date(date);
      start.setHours(0, 0, 0, 0);
      end = new Date(date);
      end.setHours(23, 59, 59, 999);
    } else if (month && year) {
      start = new Date(year, month - 1, 1);
      end = new Date(year, month, 0, 23, 59, 59, 999);
    } else if (year) {
      start = new Date(year, 0, 1);
      end = new Date(year, 11, 31, 23, 59, 59, 999);
    }

    // Build patient query
    let patientQuery = {};
    if (start && end) patientQuery.createdAt = { $gte: start, $lte: end };
    if (branch && branch !== 'All Branches') patientQuery.branch = branch;

    // Get all patients for the filter
    const patients = await Patient.find(patientQuery);

    // Sum all payments for these patients (filtering payment date as well)
    let revenue = 0;
    patients.forEach(p => {
      if (Array.isArray(p.payments)) {
        p.payments.forEach(pay => {
          let payDate = pay.date ? new Date(pay.date) : null;
          if (
            (!start && !end) ||
            (payDate && payDate >= start && payDate <= end)
          ) {
            revenue += Number(pay.amount) || 0;
          }
        });
      }
    });

    // Expense filter
    let expenseFilter = {};
    if (branch && branch !== 'All Branches') expenseFilter.branch = branch;
    if (date) {
      const d = new Date(date);
      const next = new Date(d);
      next.setDate(d.getDate() + 1);
      expenseFilter.date = { $gte: d, $lt: next };
    } else if (month && year) {
      const y = parseInt(year);
      const m = parseInt(month) - 1;
      const startE = new Date(y, m, 1);
      const endE = new Date(y, m + 1, 0, 23, 59, 59, 999);
      expenseFilter.date = { $gte: startE, $lte: endE };
    } else if (year) {
      const y = parseInt(year);
      const startE = new Date(y, 0, 1);
      const endE = new Date(y, 11, 31, 23, 59, 59, 999);
      expenseFilter.date = { $gte: startE, $lte: endE };
    }

    // Sum all expenses
    const expenseAgg = await Expense.aggregate([
      { $match: expenseFilter },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);
    const expense = expenseAgg.length > 0 ? expenseAgg[0].total : 0;

    res.json({ revenue, expense });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching revenue/expense summary', error: err.message });
  }
});

app.get('/profit-revenue-growth', async (req, res) => {
  try {
    const { year, branch } = req.query;
    if (!year) return res.status(400).json({ message: 'Year required' });
    const y = parseInt(year);

    // Prepare arrays for each month
    const months = Array.from({ length: 12 }, (_, i) => i);

    // Branch filter
    const branchFilter = branch && branch !== 'All Branches' ? { branch } : {};

    // Get all patients for the branch
    const patients = await Patient.find(branchFilter);

    // For each month, sum revenue and expenses
    const result = [];
    for (let m = 0; m < 12; m++) {
      // Revenue: sum all payments in this month
      let revenue = 0;
      patients.forEach(p => {
        if (Array.isArray(p.payments)) {
          p.payments.forEach(pay => {
            const payDate = pay.date ? new Date(pay.date) : null;
            if (
              payDate &&
              payDate.getFullYear() === y &&
              payDate.getMonth() === m
            ) {
              revenue += Number(pay.amount) || 0;
            }
          });
        }
      });

      // Expense: sum all expenses in this month
      const start = new Date(y, m, 1);
      const end = new Date(y, m + 1, 0, 23, 59, 59, 999);
      const expenseAgg = await Expense.aggregate([
        {
          $match: {
            ...branchFilter,
            date: { $gte: start, $lte: end },
          },
        },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]);
      const expense = expenseAgg.length > 0 ? expenseAgg[0].total : 0;
      const profit = revenue - expense;

      result.push({
        month: m + 1,
        revenue,
        profit,
      });
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching growth data', error: err.message });
  }
});

// Add warranty information for lab treatments
app.post('/lab-warranty', async (req, res) => {
  try {
    const warranty = new LabWarranty(req.body);
    await warranty.save();
    res.status(201).json(warranty);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});




app.get('/patients/:id/treatment-types', async (req, res) => {
  const patient = await Patient.findOne({ patientId: req.params.id }) || await Patient.findById(req.params.id);
  if (!patient) return res.status(404).json([]);
  const treatmentTypes = (patient.treatments || []).map(t => ({
    type: t.type,
  }));
  res.json(treatmentTypes);
});

// Example Express route
app.get('/bill/print/:patientId/:invoiceNo', async (req, res) => {
  try {
    const fontPath = path.join(__dirname, 'fonts', 'NotoSans-Regular.ttf');
    const { patientId, invoiceNo } = req.params;
    const patient = await Patient.findOne({ patientId: Number(patientId) });
    if (!patient) return res.status(404).send('Patient not found');

    // Search in payments array instead of bills
    const payment = (patient.payments || []).find(p => p.invoiceNo == invoiceNo);
    if (!payment) return res.status(404).send('Invoice not found');
    const treatments = patient.treatments || [];
    const payments = patient.payments || [];
    const totalEstimate = treatments.reduce((sum, t) => sum + (Number(t.estimate) || 0), 0);
    const totalPaid = (patient.payments || []).reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
    const balance = totalEstimate - totalPaid;

    // PDF generation (only after all checks pass)
    const doc = new PDFDocument();
    doc.registerFont('NotoSans', fontPath);
    doc.font('NotoSans');
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=invoice_${invoiceNo}.pdf`);
    doc.pipe(res);

    // Header
    doc.fontSize(20).text('Patient Invoice', { align: 'center' });
    doc.moveDown();

    // Invoice No
    doc.fontSize(14).text(`Invoice No: ${payment.invoiceNo}`, { align: 'left' });
    doc.fontSize(12).text(`Patient ID: ${patient.patientId}`, { align: 'left' });
    doc.text(`Name: ${patient.name}`, { align: 'left' });
    doc.text(`Phone: ${patient.phone}`, { align: 'left' });
    doc.text(`Address: ${patient.address}`, { align: 'left' });
    doc.text(`Date: ${payment.date ? new Date(payment.date).toLocaleDateString() : new Date().toLocaleDateString()}`, { align: 'left' });
    doc.moveDown();

    // Chief Complaints section (left aligned, underlined)
    doc.fontSize(14).text('Chief Complaint Details:', { underline: true, align: 'left' });
    doc.moveDown(0.5);
    doc.fontSize(12).text(patient.chiefComplaints || 'None', { align: 'left' });
    doc.moveDown();

    // Treatments section (left aligned, underlined)
    doc.fontSize(14).text('Treatment Details:', { underline: true, align: 'left' });
    doc.moveDown(0.5);

    // Table header
    const tableStartY = doc.y;
    const rowHeight = 60;
    doc.rect(50, tableStartY, 540, rowHeight).stroke('black').lineWidth(2);
    doc.fontSize(12).fillColor('black')
       .text('No.', 60, tableStartY + 12, { width: 30, align: 'left' })
       .text('Type', 100, tableStartY + 12, { width: 140, align: 'left' })
       .text('Description', 280, tableStartY + 12, { width: 180, align: 'left' })
       .text('Estimate (₹)', 440, tableStartY + 12, { width: 120, align: 'left' });

    let y = tableStartY + rowHeight;
    treatments.forEach((t, idx) => {
      doc.rect(50, y, 540, rowHeight).stroke('black').lineWidth(2);
      doc.fontSize(12).fillColor('black')
         .text(idx + 1, 60, y + 12, { width: 30, align: 'left' })
         .text(t.type || '', 100, y + 12, { width: 140, align: 'left', ellipsis: false })
         .text(t.description || '', 280, y + 12, { width: 180, align: 'left', ellipsis: false })
         .text(`₹${t.estimate || 0}`, 440, y + 12, { width: 120, align: 'left' });
      y += rowHeight;
    });
    doc.moveDown(2);

    // Payments section (left aligned, underlined)
    doc.fontSize(14).text('Payment Details:', 50, { underline: true, align: 'left' });
    doc.moveDown(0.5);

    // Table header
    doc.rect(50, doc.y, 540, 24).stroke('black').lineWidth(2);
    doc.fontSize(12).fillColor('black')
       .text('No.', 60, doc.y + 6, { width: 30, align: 'left' })
       .text('Amount (₹)', 100, doc.y + 6, { width: 120, align: 'left' })
       .text('Date', 220, doc.y + 6, { width: 120, align: 'left' })
       .text('Mode', 340, doc.y + 6, { width: 80, align: 'left' })
       .text('Txn ID', 430, doc.y + 6, { width: 120, align: 'left' });

    let py = doc.y + 24;
    const bottomMargin = 60; // Space to leave at bottom

    payments.forEach((p, idx) => {
      // If near bottom, add a new page and reset py
      if (py + 24 > doc.page.height - bottomMargin) {
        doc.addPage();
        py = 50; // Top margin for new page
        // Redraw table header on new page
        doc.rect(50, py, 540, 24).stroke('black').lineWidth(2);
        doc.fontSize(12).fillColor('black')
          .text('No.', 60, py + 6, { width: 30, align: 'left' })
          .text('Amount (₹)', 100, py + 6, { width: 120, align: 'left' })
          .text('Date', 220, py + 6, { width: 120, align: 'left' })
          .text('Mode', 340, py + 6, { width: 80, align: 'left' })
          .text('Txn ID', 430, py + 6, { width: 120, align: 'left' });
        py += 24;
      }

      doc.rect(50, py, 540, 24).stroke('black').lineWidth(2);
      doc.fontSize(12).fillColor('black')
        .text(idx + 1, 60, py + 6, { width: 30, align: 'left' })
        .text(`₹${p.amount || 0}`, 100, py + 6, { width: 120, align: 'left' })
        .text(p.date ? new Date(p.date).toLocaleDateString() : '', 220, py + 6, { width: 120, align: 'left' })
        .text(p.mode || '', 340, py + 6, { width: 80, align: 'left' })
        .text(p.transactionId || '', 430, py + 6, { width: 120, align: 'left' });
      py += 24;
    });
    doc.moveDown(2);

 

    // Totals summary table with right-aligned amounts
    const summaryStartY = doc.y;
    doc.rect(320, summaryStartY, 270, 24).stroke('black').lineWidth(2);
    doc.fontSize(12).fillColor('black')
       .text('Total Estimate', 330, summaryStartY + 6, { width: 120, align: 'left' })
       .text(`₹${totalEstimate}`, 450, summaryStartY + 6, { width: 120, align: 'right' });

    doc.rect(320, summaryStartY + 24, 270, 24).stroke('black').lineWidth(2);
    doc.fontSize(12).fillColor('black')
       .text('Total Paid', 330, summaryStartY + 30, { width: 120, align: 'left' })
       .text(`₹${totalPaid}`, 450, summaryStartY + 30, { width: 120, align: 'right' });

    doc.rect(320, summaryStartY + 48, 270, 24).stroke('black').lineWidth(2);
    doc.fontSize(12).fillColor('black')
       .text('Balance', 330, summaryStartY + 54, { width: 120, align: 'left' })
       .text(`₹${balance}`, 450, summaryStartY + 54, { width: 120, align: 'right' });

    doc.moveDown(2);


    doc.end();
  } catch (err) {
    // Only send error if headers are not already sent
    if (!res.headersSent) {
      res.status(500).send('Internal Server Error: ' + err.message);
    } else {
      console.error('PDF generation error:', err);
      // Cannot send another response here
    }
  }
});


 

  // Totals summary table with right-aligned amounts
  const summaryStartY = doc.y;
  doc.rect(320, summaryStartY, 270, 24).stroke('black').lineWidth(2);
  doc.fontSize(12).fillColor('black')
     .text('Total Estimate', 330, summaryStartY + 6, { width: 120, align: 'left' })
     .text(`₹${totalEstimate}`, 450, summaryStartY + 6, { width: 120, align: 'right' });

  doc.rect(320, summaryStartY + 24, 270, 24).stroke('black').lineWidth(2);
  doc.fontSize(12).fillColor('black')
     .text('Total Paid', 330, summaryStartY + 30, { width: 120, align: 'left' })
     .text(`₹${totalPaid}`, 450, summaryStartY + 30, { width: 120, align: 'right' });

  doc.rect(320, summaryStartY + 48, 270, 24).stroke('black').lineWidth(2);
  doc.fontSize(12).fillColor('black')
     .text('Balance', 330, summaryStartY + 54, { width: 120, align: 'left' })
     .text(`₹${balance}`, 450, summaryStartY + 54, { width: 120, align: 'right' });

  doc.moveDown(2);


  doc.end();
});

app.get('/lab-warranty/search', async (req, res) => {
  const { query } = req.query;
  if (!query) return res.json([]);
  const regex = new RegExp(query, 'i');
  const filter = {
    $or: [
      { patientName: { $regex: regex } },
      { warrantyId: { $regex: regex } },
      { patientId: isNaN(Number(query)) ? undefined : Number(query) },
      { patientPhone: isNaN(Number(query)) ? undefined : Number(query) }
    ].filter(f => !Object.values(f).includes(undefined))
  };
  const warranties = await LabWarranty.find(filter);

  // Fetch patient address and branch for each warranty
  const results = await Promise.all(warranties.map(async (w) => {
    let address = '';
    let branch = '';
    if (w.patientId) {
      const patient = await Patient.findOne({ patientId: w.patientId });
      if (patient) {
        address = patient.address || '';
        branch = patient.branch || '';
      }
    }
    return {
      ...w.toObject(),
      address,
      branch,
    };
  }));

  res.json(results);
});



