import mongoose from 'mongoose';

const appointmentSchema = new mongoose.Schema({
  patientId: Number,
  name: String,
  phone: String,
  age: Number,
  address: String,
  appointmentDate: String,
  appointmentTime: String,
  treatment: String,
  createdAt: { type: Date, default: Date.now }
});

const Appointment = mongoose.model('Appointment', appointmentSchema);

export default Appointment;