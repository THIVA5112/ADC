import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Store hashed password!
  capabilityLevel: { type: Number, default: 1 }, // 1: User, 2: Admin, 3: Manager
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

export default User;