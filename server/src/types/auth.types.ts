export interface DeviceInfo {
	fingerprint: string;
	userAgent: string;
	ip: string;
}

export interface TokenValidationResponse {
	lastUsed: Date;
	useCount: number;
}
