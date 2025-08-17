import mongoose from 'mongoose';

const treatmentSchema = new mongoose.Schema({
  type: String,
  description: String,
  estimate: Number,
});
const patientSchema = new mongoose.Schema({
  patientId: { type: Number, unique: true },
  name: { type: String, required: true },
  age: { type: Number, required: true },
  gender: { type: String, required: true },
  address: { type: String, required: true },
  phone: { type: Number, required: true },
  hasComplication: { type: Boolean, required: true },
  description: { type: String },
  chiefComplaints: String,
  treatments: [treatmentSchema],
  payments: [
    {
      amount: Number,
      date: Date, // <-- changed to String
      mode: String, // 'Cash' or 'Online'
      transactionId: String,
      invoiceNo: String, // <-- added this line
    }
  ],
  bills: [
    {
      billId: String,
      date: Date,
      treatments: [
        {
          type: String,
          description: String,
          estimate: Number,
        }
      ],
      totalEstimate: Number,
      totalPaid: Number,
      pdfUrl: String // Optional: if you want to store a link to the PDF
    }
  ],
  branch: { type: String, required: true } // Add this line
}, { timestamps: true }); // <-- this adds createdAt


export default mongoose.model('Patient', patientSchema);