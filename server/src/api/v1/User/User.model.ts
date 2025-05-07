import { model, Schema, Document } from "mongoose";
import bcrypt from "bcrypt";
import { Roles } from "../../../constants/enum";
import Helper from "../../../utils/Helper";
interface IUser extends Document {
	firstName: string;
	lastName: string;
	otherNames?: string;
	username: string;
	email: string;
	password: string;
	role: Roles;
	organization?: string;
	orgId?: string;
	isActive: boolean;
	verifyPassword(password: string): Promise<boolean>;
}
type IUserDocument = IUser & Document;
const userSchema = new Schema<IUser>(
	{
		firstName: { type: String, required: true, trim: true },
		lastName: { type: String, required: true, trim: true },
		otherNames: { type: String, trim: true },
		username: { type: String, required: true, unique: true, trim: true },
		email: { type: String, required: true, unique: true, trim: true },
		password: { type: String, required: true },
		role: { 
			type: String, 
			enum: Object.values(Roles), 
			required: true, 
			default: Roles.USER 
		},
		organization: { type: String, trim: true },
		orgId: { type: String },
		isActive: { type: Boolean, default: true },
	},
	{ timestamps: true }
);

userSchema.pre("save", async function (next) {
	this.username = await Helper.generateUsername(this.firstName, this.lastName, this.organization || "stakcast");
});
userSchema.pre("save", async function (next) {
	if (!this.isModified("password")) {
		next();
	}
	const salt = await bcrypt.genSalt(10);
	this.password = await bcrypt.hash(this.password, salt);
	next();
});
userSchema.methods.verifiedPassword = async function (enteredPassword: string) {
	return await bcrypt.compare(enteredPassword, this.password);
};

let User = model("User", userSchema);
User.syncIndexes();
export { IUserDocument, IUser };
export default User;
