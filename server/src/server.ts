import http from "http";
import "reflect-metadata";
import app from "./app";
import config from "./config/config";
import AppDataSource from "./config/DataSource";
import logger from "./config/logger";

class Server {
	private server: http.Server;
	private port: number;

	constructor() {
		this.port = (config.port as number) || 3000;
		this.server = http.createServer(app);
	}

	public async start(): Promise<void> {
		try {
			await AppDataSource.initialize();
			logger.info(`Postgres database connected`);

			const shutdown = () => {
				console.log("Shutting down gracefully...");
				this.server.close(async () => {
					console.log("Server closed");
					process.exit(0);
				});
			};

			process.on("SIGTERM", shutdown);
			process.on("SIGINT", shutdown);

			
			this.server.on("error", (error: NodeJS.ErrnoException) => {
				if (error.code === "EADDRINUSE") {
					logger.info(`Port ${this.port} is already in use, trying port ${this.port + 1}...`);
					this.port += 1;
					this.start();
				} else {
					console.error("Server error:", error);
					process.exit(1);
				}
			});

			this.server.listen(this.port, () => {
				logger.info(`${config.NODE_ENV} Server is running on port ${this.port}`);
			});
		} catch (error) {
			console.error("Error during server startup:", error);
			process.exit(1);
		}
	}
}

(async () => {
	const server = new Server();
	await server.start();
})();
