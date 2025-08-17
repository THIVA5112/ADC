import mongoose from 'mongoose';

const expenseSchema = new mongoose.Schema({
  txnId: { type: String, required: true, unique: true },
  branch: { type: String, required: true }, // <-- add this line
  type: { type: String, required: true },
  description: { type: String, required: true },
  amount: { type: Number, required: true },
  paymentMode: { type: String, enum: ['Cash', 'Online'], required: true },
  date: { type: Date, required: true },
}, { timestamps: true });

const Expense = mongoose.model('Expense', expenseSchema);
export default Expense;