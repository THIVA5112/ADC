import mongoose from 'mongoose';

const MedicationEntrySchema = new mongoose.Schema({
  date: { type: Date, required: true },
  doctorObservation: { type: String },
  treatmentPlan: { type: String },
  medicationAdvised: { type: String }
}, { _id: false });

const MedicationSchema = new mongoose.Schema({
  patientId: { type: Number, required: true },
  patientName: { type: String, required: true },
  phone: { type: Number },
  branch: { type: String },
  history: [MedicationEntrySchema] // Array of medication entries
});

export default mongoose.model('Medication', MedicationSchema);
