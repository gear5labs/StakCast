import express from "express";
import { ErrorHandler } from "./utils/errorHandler";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";
import "reflect-metadata";

import appRoutes from ".";
import { setupSwagger } from "./docs/swagger";

const app= express();
import "express";
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json());

app.use(express.urlencoded({ extended: true }));

setupSwagger(app);

app.get("/", (req, res) => {
	res.send("Hello World!");
});

app.use("/api", appRoutes);
app.use(ErrorHandler);

export default app;
