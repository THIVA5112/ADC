import mongoose from 'mongoose';

const labWarrantySchema = new mongoose.Schema({
  warrantyId: { type: String, required: true, unique: true },
  patientId: { type: Number, required: true },
  patientName: { type: String, required: true },
  patientPhone: { type: Number, required: true },
  patientAddress: { type: String, required: true },
  treatmentType: { type: String, required: true },
  material: { type: String, required: true },
  product: { type: String, required: true },
  labName: { type: String, required: true },
  date: { type: String, required: true },
  warrantyYears: { type: Number, required: true },
});

export default mongoose.model('LabWarranty', labWarrantySchema);
