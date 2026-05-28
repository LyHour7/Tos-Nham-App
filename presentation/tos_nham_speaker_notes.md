# Tos Nham App Speaker Notes

## 1. Title
Today I will present Tos Nham App, a multi-branch restaurant management system built with Flutter. The goal is to connect customers, staff, and restaurant operations in one digital workflow.

## 2. Project Problem
Restaurants often manage reservations, orders, and payments separately. This can cause fake bookings, slow service, and unclear order status. Tos Nham App solves this by centralizing the main workflows.

## 3. Solution
The system supports three roles: customer, staff, and admin. Customers book and order, staff manage daily operations, and admins control branches, menu items, payments, and reports.

## 4. Objectives
The main objectives are to reduce waiting time, prevent fake reservations with deposits, make check-in secure with QR scanning, and centralize operations across branches.

## 5. Customer Journey
The customer starts by logging in, choosing a branch, browsing menu items, adding items to cart, then either booking a table or ordering online. After payment, they can track the status.

## 6. Reservation Flow
For reservations, the customer selects date, time, table, and branch. The system calculates a 50 percent deposit, generates payment flow, and creates a QR code for staff check-in.

## 7. Online Ordering
For online orders, the customer selects menu items from one branch, checks out, and pays. Staff can view incoming orders and update the order status from pending to completed.

## 8. System Architecture
The frontend is Flutter. It communicates with a REST API built with Node.js and Express. The backend handles authentication, role permissions, branch data, orders, reservations, payments, and reviews.

## 9. Tech Stack
The Flutter app uses REST API calls, shared preferences for stored authentication data, QR packages for reservation flow, mobile scanner for check-in, and image picker for receipt uploads.

## 10. Recent Improvement
One recent issue was that users could rate an item, but the total rating did not update immediately. I fixed this by refreshing the item details after submit and syncing the average rating and total rating count in the UI.

## 11. Benefits
For restaurants, the app improves table planning, branch management, and staff workflow. For customers, it gives a smoother booking, ordering, payment, and review experience.

## 12. Future Improvements
Future improvements include realtime payment verification, push notifications, delivery tracking, loyalty rewards, analytics, and stronger Khmer and English language support.

## 13. Conclusion
In conclusion, Tos Nham App brings reservation, ordering, payment, QR check-in, and staff operations into one system. It helps restaurants serve customers faster and manage branches more clearly.
