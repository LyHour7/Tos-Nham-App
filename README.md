# 🍽 Tos-Nham-App

Multi-Branch Restaurant Management System  
Flutter Frontend + Node.js Backend

---

## 📌 Project Overview

**Tos-Nham-App** is a multi-branch restaurant management system that provides:

- Table booking with 50% deposit
- QR-based reservation check-in
- Online food ordering
- ABA KHQR payment integration
- Payment receipt verification
- Role-based access control (Admin, Staff, Customer)

The system is designed to improve restaurant operational efficiency and provide a modern digital ordering experience.

---

## 🎯 Objectives

- Reduce waiting time
- Prevent fake reservations using deposit system
- Provide secure QR-based check-in
- Enable online ordering with payment tracking
- Centralize multi-branch management
- Implement clean and scalable architecture

---

## 👥 User Roles

### 👤 Customer
- Register & Login
- Select branch
- Browse menu
- Add to cart
- Book table (50% deposit)
- Generate QR code
- Place online orders
- Upload payment receipt
- Track order status
- Manage profile & address

### 👨‍🍳 Staff
- View dashboard
- Scan QR for reservation check-in
- View reservations
- View orders
- Update order status
- View payment status

### 🧑‍💼 Admin
- Manage branches
- Manage menu items
- Monitor reservations
- Monitor online orders
- Verify uploaded receipts
- View sales reports

---

## 💳 Payment Integration (ABA KHQR)

The system supports ABA KHQR payment flow:

1. Backend generates KHQR code
2. Customer scans QR using ABA app
3. Customer uploads payment receipt
4. Admin verifies payment
5. Staff prepares order

Payment Status:
- Pending Verification
- Verified
- Rejected

---

## 🏗 System Architecture

Frontend (Flutter)
↓
REST API (Node.js + Express)
↓
Database (MySQL / PostgreSQL)

Backend Responsibilities:
- Authentication (JWT)
- Role-based access control
- Branch-based data separation
- Order & reservation management
- Payment verification
- QR validation

---

## 🛠 Tech Stack

### Frontend
- Flutter
- Provider (State Management)
- REST API Integration

### Backend
- Node.js
- Express.js
- JWT
- bcrypt
- Multer (file upload)

### Database
- MySQL / PostgreSQL

---


## 🔐 Role-Based Access

| Role      | Access Scope |
|-----------|--------------|
| Admin     | Full system control |
| Staff     | Operational management |
| Customer  | Personal account only |

---

## 📊 Status Workflow

### Order Status
- Pending
- Confirmed
- Preparing
- Ready
- Completed
- Cancelled

### Reservation Status
- Pending Payment
- Confirmed
- Arrived
- Completed
- Cancelled

---

## 📌 Future Improvements

- Real-time payment verification (ABA API webhook)
- Push notifications
- Delivery tracking system
- Loyalty & reward program
- Multi-language support

---

## 📄 License

This project is developed for academic purposes.
