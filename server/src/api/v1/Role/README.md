# Role Management API Documentation

This module provides comprehensive role management functionality for the StakCast backend, including role assignment, revocation, querying, and synchronization with smart contract events.

## Features

- **Role-based Access Control**: Three role levels (admin, moderator, user) with hierarchical permissions
- **Contract Integration**: Sync with blockchain events (ModeratorAdded, ModeratorRemoved)
- **Audit Trail**: Track role assignments with assignedBy, timestamps, and transaction hashes
- **Resource Protection**: Middleware for role-based route protection
- **Management Tools**: Admin utilities for role system initialization and validation

## Role Hierarchy

1. **Admin**: Full system access, can assign/revoke any role
2. **Moderator**: Can create/resolve markets, view role statistics
3. **User**: Basic user permissions

## API Endpoints

### Authentication Required

All endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer <jwt-token>
```

### Role Assignment & Management

#### POST `/api/v1/roles/assign`

**Admin Only** - Assign a role to a user

```json
{
	"userId": "string",
	"role": "admin|moderator|user",
	"contractAddress": "string (optional)",
	"transactionHash": "string (optional)"
}
```

#### DELETE `/api/v1/roles/revoke`

**Admin Only** - Revoke a role from a user

```json
{
	"userId": "string",
	"role": "admin|moderator|user"
}
```

### Role Queries

#### GET `/api/v1/roles/user/:userId`

**Resource Access Control** - Get user's roles (users can see their own, admin/moderator can see any)

Response:

```json
{
	"message": "User roles retrieved successfully",
	"data": {
		"roles": [
			{
				"id": "string",
				"role": "admin|moderator|user",
				"userId": "string",
				"assignedBy": "string",
				"contractAddress": "string",
				"transactionHash": "string",
				"isActive": true,
				"createdAt": "datetime",
				"updatedAt": "datetime",
				"user": {
					"id": "string",
					"email": "string",
					"firstName": "string",
					"lastName": "string"
				}
			}
		],
		"highestRole": "admin|moderator|user"
	}
}
```

#### GET `/api/v1/roles/check/:userId/:role`

**Resource Access Control** - Check if user has specific role

Response:

```json
{
	"message": "Role check completed",
	"data": {
		"hasRole": true
	}
}
```

#### GET `/api/v1/roles/query`

**Moderator+** - Query roles with filters

Query Parameters:

- `userId`: Filter by user ID
- `role`: Filter by role type
- `isActive`: Filter by active status (true/false)
- `contractAddress`: Filter by contract address

#### GET `/api/v1/roles/users/:role`

**Moderator+** - Get all users with specific role

#### GET `/api/v1/roles/stats`

**Moderator+** - Get role statistics

Response:

```json
{
	"message": "Role statistics retrieved successfully",
	"data": {
		"totalUsers": 100,
		"adminCount": 2,
		"moderatorCount": 5,
		"userCount": 93
	}
}
```

### Contract Integration

#### POST `/api/v1/roles/sync-contract-event`

**Admin Only** - Sync role changes from contract events

```json
{
	"eventType": "ModeratorAdded|ModeratorRemoved",
	"moderatorAddress": "string",
	"transactionHash": "string",
	"contractAddress": "string"
}
```

### Management Endpoints

#### POST `/api/v1/roles/management/init-defaults`

**Admin Only** - Initialize default USER role for all existing users

#### POST `/api/v1/roles/management/create-admin`

**Admin Only** - Create initial admin user

```json
{
	"adminEmail": "admin@example.com"
}
```

#### POST `/api/v1/roles/management/migrate`

**Admin Only** - Migrate existing users to role system

#### GET `/api/v1/roles/management/validate`

**Admin Only** - Validate role system integrity

Response:

```json
{
	"message": "Role system validation completed",
	"data": {
		"isValid": true,
		"issues": [],
		"stats": {
			"totalUsers": 100,
			"adminCount": 2,
			"moderatorCount": 5,
			"userCount": 93
		}
	}
}
```

#### POST `/api/v1/roles/management/start-listener`

**Admin Only** - Start contract event listener

#### POST `/api/v1/roles/management/stop-listener`

**Admin Only** - Stop contract event listener

#### GET `/api/v1/roles/management/listener-status`

**Admin Only** - Get event listener status

#### POST `/api/v1/roles/management/sync-missed-events`

**Admin Only** - Sync missed contract events

```json
{
	"fromBlock": 12345,
	"toBlock": 12350
}
```

## Middleware

### Role-based Access Control

#### `requireRole(role: UserRole)`

Requires user to have exact role

#### `requireMinRole(role: UserRole)`

Requires user to have minimum role level (admin > moderator > user)

#### `requireResourceAccess(resourceUserIdParam?: string)`

Allows users to access their own resources, admin/moderator can access any

#### `addUserRole`

Adds user role to request object without enforcing access control

## Database Schema

### user_roles Table

```sql
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'moderator', 'user')),
  user_id UUID NOT NULL REFERENCES users(id),
  assigned_by VARCHAR(255),
  contract_address VARCHAR(255),
  transaction_hash VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Error Responses

All errors follow this format:

```json
{
	"error": "Error message description"
}
```

### Common Error Codes

- `401`: Unauthorized (no token or invalid token)
- `403`: Forbidden (insufficient role permissions)
- `400`: Bad Request (invalid input data)
- `404`: Not Found (user/role not found)
- `500`: Internal Server Error

## Usage Examples

### Assign Admin Role

```bash
curl -X POST http://localhost:3000/api/v1/roles/assign \
  -H "Authorization: Bearer <admin-jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-uuid",
    "role": "admin"
  }'
```

### Check User Role

```bash
curl -X GET http://localhost:3000/api/v1/roles/check/user-uuid/admin \
  -H "Authorization: Bearer <jwt-token>"
```

### Get Role Statistics

```bash
curl -X GET http://localhost:3000/api/v1/roles/stats \
  -H "Authorization: Bearer <moderator-or-admin-jwt-token>"
```

## Contract Event Integration

The system automatically syncs with smart contract events:

1. **ModeratorAdded Event**: Automatically assigns moderator role
2. **ModeratorRemoved Event**: Automatically revokes moderator role

Events include transaction hash for audit trail and can be manually synced if missed.

## Security Considerations

1. **Role Hierarchy**: Enforced at middleware level
2. **Audit Trail**: All role changes are logged with timestamps and assignedBy
3. **Contract Sync**: Blockchain events provide immutable audit trail
4. **Resource Protection**: Users can only access their own data unless they have elevated privileges
5. **Token Validation**: All endpoints require valid JWT authentication

## Deployment Notes

1. Run database migrations to create user_roles table
2. Initialize default roles: `POST /api/v1/roles/management/init-defaults`
3. Create initial admin: `POST /api/v1/roles/management/create-admin`
4. Start contract event listener: `POST /api/v1/roles/management/start-listener`
5. Validate system: `GET /api/v1/roles/management/validate`
