import mongoose from "mongoose";
const { Schema, model } = mongoose;

interface IAuthModel {
	userId: mongoose.Schema.Types.ObjectId;
	token: string;
	deviceInfo: {
		fingerprint: string;
		userAgent: string;
		ip: string;
	};
	lastUsed: Date;
	useCount: number;
	maxUses: number;
}

const authSchema = new Schema<IAuthModel>({
	userId: { type: Schema.Types.ObjectId, required: true },
	token: { type: String, required: true },
	deviceInfo: {
		fingerprint: { type: String, required: true },
		userAgent: { type: String, required: true },
		ip: { type: String, required: true },
	},
	lastUsed: { type: Date, default: Date.now },
	useCount: { type: Number, default: 0 },
	maxUses: { type: Number, default: 50 },
});

const AuthModel = model("AuthModel", authSchema);

export { IAuthModel };
export default AuthModel;
