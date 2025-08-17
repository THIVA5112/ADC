import mongoose from 'mongoose';

const treatmentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String },
  defaultEstimate: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

const Treatment = mongoose.model('Treatment', treatmentSchema);

export default Treatment;

// --- Seed data function ---
export async function seedTreatments() {
  const treatments = [
    'ROOT CANAL TREATMENT',
    'IMPLANTS',
    'ALIGNERS',
    'BRACES',
    'FILLING',
    'EXTRACTION',
    'WISDOM TOOTH',
    'SCALING',
    'VENERS',
    'WHITENING',
    'CROWNS BRIDGES',
  ];

  for (const name of treatments) {
    const exists = await Treatment.findOne({ name });
    if (!exists) {
      await Treatment.create({ name });
    }
  }
  console.log('Treatments seeded!');
}