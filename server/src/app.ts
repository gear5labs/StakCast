import express, { Application } from "express";
import { ErrorHandler } from "./utils/errorHandler";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";
import { container } from "tsyringe";
import QueueService from "./services/queueService";

import appRoutes from ".";
const app: Application = express();
import "express";
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json());

app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
	res.send("Hello World!");
});

app.use("/api", appRoutes);
app.use(ErrorHandler);

// Initialize queue service as singleton
if (!container.isRegistered(QueueService)) {
	const queueService = new QueueService();
	container.registerInstance(QueueService, queueService);
}

export default app;
