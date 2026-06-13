# WWorker Mobile App: Web Functional Specification

**Document purpose:** Define the current Flutter mobile application's screens, workflows, business rules, API usage, state, permissions, and UI behavior so a web frontend can reproduce the same functionality.

**Source of truth:** The Flutter code in this repository, reviewed on June 12, 2026. Where the API returns more fields than the UI uses, the web implementation should preserve the response object and render the fields described here.

## 1. Product Structure

WWorker is a company-scoped business management application. Its main workflow is:

1. Create or select a company.
2. Create products and materials.
3. Build a Bill of Materials (BOM).
4. Apply overhead and markup to obtain cost and selling prices.
5. Create a client quotation from one or more BOMs.
6. Convert a quotation into an order.
7. Assign staff and track order status.
8. Record payments and issue receipts.
9. Generate and manage invoices.
10. Manage all saved records from the Database section.

The authenticated app has five primary navigation destinations:

| Tab | Mobile screen | Purpose |
|---|---|---|
| Home | `Home` | Summary, quick actions, recent products and quotations |
| Quotation | `AllQuotations` | Working BOM list, BOM import, quotation creation |
| Orders | `AllOrdersPage` | Order list, assignment, status management |
| Sales | `SalesPage` | Sales totals, payments, balances, receipts |
| Settings | `Settings` | Company, staff, overhead, materials, invoice and platform settings |

The mobile app keeps these tabs alive as the user switches between them. The web app should preserve filters and unsaved screen state when navigating between primary sections where practical.

## 2. Global Application Rules

### 2.1 Authentication and company scope

- All business API requests require the saved bearer token.
- Most data is scoped to the active company.
- A user can belong to multiple companies.
- Switching company changes the active company context and must refresh company-scoped data.
- A user without a company can enter the dashboard, but company-dependent quick actions must show a create-company prompt instead of opening their normal flow.
- Roles are principally `owner`, `admin`, and staff roles returned by the API.
- Platform-owner tools are separate from company-owner/admin tools and only appear when `isPlatformOwner` is true.

### 2.2 Loading and feedback

Every data screen must support:

- Initial loading state.
- Error state with Retry.
- Empty state with a relevant action where applicable.
- Pull-to-refresh on mobile; use a Refresh action or equivalent on web.
- Disabled and loading button states during submission.
- Success and error feedback after mutations.
- Confirmation before destructive actions.
- API token/session errors must return the user to Sign In after clearing the invalid session.

### 2.3 Monetary values

- Currency is displayed as Nigerian naira using the `₦` symbol.
- Format money with grouping separators and two decimals when precision matters.
- Do not use formatted strings in calculations. Keep numeric values as numbers and format only for display.

### 2.4 Dates

- Date pickers are used for quotation duration, order schedules, payment dates, invoice due dates, and receipt dates.
- Payment dates cannot be in the future.
- Order end date cannot be earlier than its start date.
- API payloads use ISO-8601 date strings unless the endpoint already expects another format.

### 2.5 Shared visual language

Use the mobile app's visual identity:

- Page background: `#FAF7F3`.
- Main text: `#211D1A` or `#302E2E`.
- Muted text: `#756A61`.
- Primary brown: `#8B4513` / `#A16438`.
- Border: `#E8DED6`.
- White cards with subtle shadows.
- Card radius: normally 16-24px.
- Input/button radius: normally 10-16px.
- Selected chips: light brown background, brown border and text.
- Destructive actions: red.
- Positive/success values: green.

On desktop, keep the same grouping and action hierarchy but use responsive columns, a constrained content width, and a left navigation or equivalent persistent navigation. Bottom sheets may become right drawers or centered dialogs, but their fields and confirmation steps must remain the same.

## 3. Session and Authentication

### 3.1 Session Gate

**Entry:** Application startup.

**Behavior:**

1. Read the locally stored token.
2. If no token exists, show Onboarding.
3. If a token exists, call `GET /api/auth/me`.
4. If the token is valid and the user has companies, open Company Selection.
5. If valid and no company is available, open the Dashboard.
6. On a token/authentication failure, clear the session and show Sign In.
7. On a non-auth network failure, use cached company data when available; otherwise open Dashboard.

### 3.2 Onboarding

Three slides:

1. **Simplify Your Quotation Process**
2. **Turn Ideas into Quotes**
3. **Let's Create Your First Quote**

Controls:

- `Next` advances a slide.
- Final `Get Started` opens Sign Up.
- `Skip` opens Sign Up.
- Web may present this as a carousel, but slide order and calls to action must remain.

### 3.3 Sign Up

**Fields:**

- Full name, required.
- Email, required and valid.
- Phone number, required.
- Password, required, minimum 8 characters.
- Company name, optional.
- Company email, optional.

**Submit:** `POST /api/auth/signup`.

**Result:** Save any returned session/user data and continue to the authenticated flow, or direct the user to Sign In according to the response.

### 3.4 Sign In

**Fields:** Email and password, both required.

**Submit:** `POST /api/auth/signin`.

**On success:**

- Store token and user identity.
- Store platform-owner status.
- Store accessible companies and active company fields.
- Open Company Selection when multiple/access-controlled companies exist; otherwise enter Dashboard.

**Other actions:** Forgot Password opens the recovery flow.

The mobile code contains saved-login credential keys. The web implementation must not store a plaintext password. Use secure token/session storage.

### 3.5 Forgot and Reset Password

1. Recovery screen chooses/provides the recovery identity.
2. Request OTP with `POST /api/auth/forgot-password`.
3. Verify OTP with `POST /api/auth/verify-otp`.
4. Save the returned reset token temporarily.
5. Enter new password and confirmation.
6. Submit with `POST /api/auth/reset-password`.
7. Return to Sign In after success.

Password confirmation must match before submission.

### 3.6 Change Password

Authenticated password changes use `POST /api/auth/change-password`.

### 3.7 Log Out

- Call the app logout routine.
- Clear token, identity, company, role, and cached session fields.
- Replace the current route with Sign In so Back cannot reopen authenticated content.

## 4. Company Selection and Company Management

### 4.1 Company Selection

**API:** `GET /api/auth/companies`.

**Presentation:**

- Show only companies for which access is granted.
- Support refresh.
- Each card shows available company identity/status details.

**Selection:**

1. Call `POST /api/auth/switch-company`.
2. Save active company, role, position, and company contact fields.
3. Open Dashboard and reload company-scoped data.

### 4.2 Create Company

**Fields:**

- Company name, required.
- Email, optional.
- Phone, optional.
- Address, optional.

**API:** `POST /api/auth/company`.

After success, refresh the company list and make the company available for selection.

### 4.3 Edit Company

Company changes use `PUT /api/auth/company/{index}`. Pre-fill the current company data and preserve unchanged fields.

## 5. Home Dashboard

### 5.1 Header

- Greet the user by first name.
- Show active company name.
- Show notification action and unread state.
- A company-less user sees company creation guidance.

### 5.2 Quick Actions

| Action | Destination/behavior |
|---|---|
| Create Quotation | Quotation workspace |
| Add Product | Product form in create mode |
| Generate Invoice | Client selection for invoice generation |
| Database | Database home |
| Order | Choice sheet: Create Order or View Orders |
| Sales | Sales dashboard |

Company-dependent actions must be blocked by the no-company prompt.

### 5.3 Recent Quotations

- Load from `GET /api/quotation`.
- Show up to five recent records.
- Cards show client/quotation identity and pricing/status data available in the model.
- Tapping follows the quotation detail/continuation behavior used by the quotation module.

### 5.4 Recent Products

- Load from `GET /api/product/`.
- Show up to ten.
- Tapping opens Product Edit.

Refresh reloads products and quotations together.

## 6. Notifications

**Screen:** Notifications list.

**Capabilities:**

- Paginated loading.
- Unread count.
- Mark one notification as read.
- Mark all as read.
- Delete notification.
- Loading, empty, error, and retry states.

**API family:** `/api/notifications`, including read, mark-all-read, unread-count, and delete operations exposed by the service.

## 7. Products

### 7.1 Add/Edit Product

**Fields:**

- Product image, required by the current form.
- Product name, required.
- Description, required.
- Category/type, required.
- Subcategory, required.

**API:**

- Create: `POST /api/product/`.
- Edit: `PUT /api/product/{id}`.

**Post-save behavior:**

- When launched from Home, return to Home.
- When launched during BOM creation, continue to BOM Summary.

### 7.2 Select Existing Product

- Load product catalog from the product API.
- Search by product name, ID, category, or related displayed metadata.
- Selecting a product either returns it to the caller or opens it in the relevant product/BOM continuation flow.
- Preserve the selected product's ID, name, description, image, category, and subcategory.

## 8. Materials and Material Catalog

### 8.1 Material Selector Used in BOMs

**APIs:**

- `GET /api/product/materials?limit=500`
- `GET /api/product/materials/grouped?limit=500`
- `GET /api/product/materials/supported`
- `GET /api/product/materials/supported/summary`

The selector has four dependent rows:

1. Category.
2. Subcategory.
3. Unit.
4. Size/color variant.

Rules:

- A row appears when the preceding selection has valid options.
- Changing an earlier row clears incompatible later selections.
- Search filters available material choices.
- Material data must be taken from the API/database, not hard-coded.
- The response is ETag-cached on mobile. Web should use normal HTTP cache/ETag behavior and invalidate after material creation or updates.

### 8.2 Quantity and Area Rules

Only a material whose selected unit is `sqm` uses project length and width.

| Material unit | Input shown | Numeric type |
|---|---|---|
| sqm | Length, width, and dimension unit | Float |
| Yard | Quantity | Float |
| Piece | Quantity | Integer |
| Bag | Quantity | Integer |
| Pair | Quantity | Integer |
| Pack | Quantity | Integer |
| Set | Quantity | Integer |
| Roll | Quantity | Integer |
| Liter | Quantity | Float |
| Pound Weight | Quantity | Float |
| Gallon | Quantity | Float |
| Kilogram | Quantity | Float |

Do not show length and width for a non-`sqm` material.

For `sqm`:

- Ask for the project's longer dimension and shorter dimension.
- Ask for the dimension unit.
- Send the material ID and dimensions to `POST /api/product/material/{materialId}/calculate-cost`.
- Use the API's billable units, quantity, calculation metadata, and line total.
- If the API indicates that quantity mode should be used, fall back to the normal quantity field.

For non-`sqm`:

- Quantity must be greater than zero.
- Integer units reject decimal quantities.
- Float units accept decimal quantities.
- Line total is quantity multiplied by unit price unless the API returns an authoritative total.

Unpriced materials require a manual price before they can be added to a priced BOM.

### 8.3 Added Material Record

Preserve these values in the working BOM:

- Material ID and display name.
- Category and subcategory.
- Unit, size/color variant, and billing mode.
- Length, width, thickness, dimension unit, and computed square meters where applicable.
- Entered quantity and billable quantity.
- Unit price, manual-price status, and line total.
- API calculation response/metadata.
- Associated product name when assigned.

## 9. Company Material Upload

**Entry:** Settings > Material Upload.

The screen has two modes:

- **Create New:** Build a new company material and submit it for approval.
- **Edit Existing:** Pick an existing saved material and update it.

### 9.1 Material fields

- Image.
- Category: Wood, Board, Foam, Fabric, Marble, Hardware, Paint, Adhesive, Nail, or Other.
- Custom category name when Other is selected.
- Auto-generated material name.
- Subcategory, required, with API-backed suggestions.
- Unit, required.
- Thickness and thickness unit for `sqm`.
- Free-text size for non-`sqm`.
- Optional color.
- Standard width and length plus standard unit when sheet dimensions apply.
- Optional notes.
- Pricing unit.
- For `sqm`, pricing basis: `SQM` or `Sheet Size`.
- Optional price per unit.

Supported units are Piece, Yard, Bag, Pair, Pack, Set, Roll, sqm, Liter, Pound weight, Gallon, and Kilogram.

### 9.2 Validation and payload behavior

- Category and subcategory are required.
- `sqm` requires a positive thickness and valid standard width/length.
- If either standard dimension is entered, both must be valid positive values.
- Price may be empty; such a material is flagged for later manual pricing.
- `sqm` uses `billingMode: area_prorated`.
- New materials include `useCatalog: false`.
- Edit Existing requires a selected material ID.

**API:**

- New: multipart `POST /api/product/creatematerial`.
- Existing: material update endpoint exposed by `MaterialService`.
- Grouped saved materials: Database grouped-material endpoint.

**Success messages:**

- New: Material submitted for approval.
- Existing: Material updated successfully.

## 10. BOM and Quotation Workspace

### 10.1 Working Quotation/BOM List

**Screen:** Quotation primary tab (`AllQuotations`).

This is a local working list, not only the API quotation archive.

**Summary values:**

- Total cost.
- Total selling price.
- Margin.

**Per item:**

- Product/BOM identity.
- Material and additional-cost breakdown.
- Quantity stepper with plus and minus.
- Edit breakdown.
- Delete from working list.

**Primary actions:**

- `Create`: start a new BOM in Add Material.
- `Import`: import an existing saved BOM.
- `Continue`: create a client quotation from selected working BOMs.

Continue is disabled when the working list is empty.

### 10.2 Local draft persistence

The mobile app stores:

- Current BOM materials and additional costs.
- Current product/BOM summary.
- Working quotation/BOM list.
- Quantity selected for each working item.

The web app should persist drafts per authenticated user, preferably server-side when an endpoint exists, otherwise in user-scoped browser storage. Never mix drafts between users or active companies.

### 10.3 Add Material Screen

Contains:

- Material selector and pricing form.
- Other/Additional Cost form.
- Current material list with edit/delete.
- Current additional-cost list with edit/delete.

At least one material or additional cost is required to continue.

After Continue, choose:

- Create New Product.
- Select Existing Product.

The chosen product is attached to the BOM materials and used throughout BOM summary, quotation, invoice, order, and receipt display.

### 10.4 Additional Costs

Additional costs are separate from materials.

They contain:

- Name/category.
- Description where available.
- Amount.
- Duration/period where applicable.
- Source metadata when selected from saved overhead costs.

They contribute to BOM pricing according to the selected overhead calculation method.

### 10.5 Import Saved BOM

1. Fetch saved BOMs with `GET /api/bom`.
2. Show searchable/selectable BOM cards.
3. Allow the user to inspect and edit imported materials/additional costs before adding.
4. Add the selected BOM to the local working quotation list.
5. Preserve API IDs and pricing metadata.

The legacy Import Quotations screen can select multiple API quotations and import their BOM content. Web should expose this only if product requirements retain the legacy route; the principal Import action imports BOMs.

### 10.6 Edit BOM Breakdown

The edit sheet/dialog must:

- List materials and additional costs separately.
- Allow editing material name, dimensions, unit, quantity/sqm, and pricing values supported by the record.
- Allow removing a material or cost.
- Allow adding a custom cost.
- Allow selecting a saved overhead cost.
- Recalculate totals after every confirmed change.

## 11. BOM Summary and Pricing

### 11.1 Summary contents

- Product identity.
- Material list and total.
- Additional costs and total.
- Manufacturing overhead.
- Cost price.
- Markup.
- Selling price.
- Expected duration value and period/unit.

### 11.2 Pricing methods

The app supports:

**Method 1: Direct Markup**

- Manufacturing overhead is excluded from cost-price calculation.
- Cost is based on materials and direct additional costs.
- Markup is applied to the resulting cost.

**Method 2: Include Manufacturing Overhead Cost**

- Allocated manufacturing overhead is included in cost price.
- Markup is applied after overhead inclusion.

Pricing settings include:

- Selected method.
- Markup percentage.
- Working days/month assumptions used by the overhead calculator.

The web implementation must use the same calculation order as mobile and must not calculate from formatted currency strings.

### 11.3 Save BOM

**API:** `POST /api/bom`.

Payload includes:

- Product object/reference.
- BOM name and description.
- Materials.
- Optional additional costs.
- Pricing object.
- Expected duration and/or due date.

Additional costs can also be added through `POST /api/bom/{id}/additional-costs`.

## 12. Create a Client Quotation

### 12.1 Client Details

**Entry:** Continue from the working BOM list.

**Existing clients:** `GET /api/sales/get-clients`.

The client picker:

- De-duplicates client names.
- Sorts clients.
- Supports search.
- Selecting a client fills known name, email, phone, address, and nearest bus stop.
- A new client may be entered manually.

**Fields:**

- Client name.
- Email.
- Phone number.
- Address.
- Nearest bus stop.
- Description.

The description is initially generated from selected products but remains editable.

### 12.2 Quotation Review and Submit

The review screen:

- Shows each selected BOM/product.
- Applies the quantity selected in the working list.
- Calculates item and grand cost/selling totals.
- Shows expected duration/period.
- Preserves material and overhead breakdowns.

**API:** `POST /api/quotation`.

Payload contains:

- Client contact/location details.
- Quotation items/BOMs and quantities.
- Service/product summary.
- Discount, initially zero in this flow.
- Expected duration and period.
- Cost price.
- Overhead cost.
- Product ID where available.

### 12.3 Success behavior

After creation:

1. Ask whether to create an invoice now.
2. Clear/reset the completed working quotation flow.
3. Return to the Quotation tab.
4. If the user chooses invoice creation, open Invoice Preview for the newly created quotation. If direct preview data is unavailable, open the client's quotation list in invoice mode.

## 13. Saved Client Quotations

**API:** `GET /api/quotation`.

Capabilities:

- List all quotations.
- Filter to a client when opened from invoice flow.
- Show quotation number, client, dates, totals, status, items/BOMs, discount, cost, overhead, and final total when available.
- Delete a quotation.
- Open item/BOM details.
- Add one or all quotation items back into the BOM working draft.
- In invoice mode, tapping a quotation opens Invoice Preview.

Quotation data model includes client details, items, BOMs, service, expected duration, cost price, overhead, discount, total cost, total selling price, discount amount, final total, status, number, and timestamps.

## 14. Overhead Costs

**Entry:** Settings > Overhead Cost.

### 14.1 Overhead list

- Group/filter by category.
- Show cost, description, duration, and period.
- Show total for the selected duration/context.
- Allow deletion.
- Make saved overhead entries selectable from BOM editing.

### 14.2 Add overhead

**Fields:**

- Category.
- Description.
- Cost.
- Duration value.
- Duration period.

Validate required text and positive numeric cost/duration values.

### 14.3 Persistence and synchronization

The mobile screen uses local-first storage and API synchronization:

- Local key: overhead costs collection.
- Create: `POST /api/oc/create-oc`.
- Read: `GET /api/oc/get-oc`.
- Delete: `DELETE /api/oc/delete-oc/{id}`.

Show sync state and provide a Save & Sync/retry action when local changes are not synchronized.

## 15. Orders

### 15.1 Create Order: Select Quotation

- Load quotations from `GET /api/quotation`.
- Optionally filter/search by client.
- Selecting a quotation opens Order Preview.

### 15.2 Order Preview

Display:

- Quotation and client details.
- Available BOMs/items.
- Totals and relevant service data.

The user may create an order from all or a subset of the quotation BOMs.

For every selected BOM:

- Start date is required.
- End date is required.
- End date must be on or after start date.

Overall order dates:

- Start date is the earliest selected BOM start date.
- End date is the latest selected BOM end date.

Optional fields:

- Amount already paid.
- Notes.

**API:** `POST /api/orders/create`.

Payload:

- `quotationId`
- `startDate`
- `endDate`
- selected `bomIds`
- `notes`
- `amountPaid`

On success, return to the Orders tab.

### 15.3 Order List

**API:** `GET /api/orders/get-orders`.

Supports:

- Pagination.
- Search.
- Status filter.
- Payment filter.
- Assignment filter.
- Refresh.

Statuses:

- Pending.
- In Progress.
- Completed.
- On Hold.
- Cancelled.

Normalize API values such as `inprogress`, `in_progress`, and display labels consistently.

Each order card shows order/client identifiers, schedule, status, payment status, totals/balance, and assignment where available.

Actions:

- Update status.
- Assign or reassign staff.
- Unassign staff.
- Delete order.
- Open receipt from Sales.

### 15.4 Update Status

**API:** `PATCH /api/orders/update-orders/{id}/status`.

- Present the five supported statuses.
- Disable submit when the status has not changed.
- Refresh the order after success.

### 15.5 Staff Assignment

**API:**

- Available staff: `GET /api/orders/staff/available`.
- Assign: `POST /api/orders/{id}/assign`.
- Unassign: corresponding order unassign endpoint in `OrderService`.

The sheet/dialog:

- Shows current assignee.
- Lists available staff.
- Allows one staff selection.
- Accepts optional assignment notes.
- Supports unassigning.

### 15.6 Delete and statistics

- Delete: `DELETE /api/orders/delete-orders/{id}`.
- Statistics: `GET /api/orders/stats`.
- Confirm before delete.

## 16. Sales and Payments

### 16.1 Sales Dashboard

Sales uses order data and computes:

- Total sales.
- Amount received.
- Outstanding balance.

Capabilities:

- Search.
- Filter by payment state.
- Filter by order state.
- View order/client/payment summary.
- Add payment.
- View/generate receipt.

### 16.2 Add Payment

**Fields:**

- Amount, required.
- Payment method: Cash, Transfer, Card, or Cheque.
- Payment date, cannot be future.
- Optional reference.
- Optional notes.

Rules:

- Amount must be greater than zero.
- Amount cannot exceed the current order balance.
- Display comma formatting without changing the numeric submitted value.

**API:** `POST /api/orders/orders/{id}/payment`.

Refresh Sales and the affected order after success.

### 16.3 Sales Analytics

**APIs:**

- `GET /api/sales/get-sales`
- `GET /api/sales/get-inventory`

The screen supports period filtering and presents:

- Sales metric cards.
- Sales performance chart.
- Project type distribution.
- Summary values.
- Inventory/stock bars.

This is a secondary analytics screen and should be linked from the web Sales area even if the current mobile route is not always prominent.

## 17. Receipts

### 17.1 Receipt Preview

**Entry:** Sales > order > View Receipt.

Receipt content is derived from the order:

- Client contact/location details.
- Receipt number: `RCPT-{orderNumber}`.
- Quotation/order reference.
- Receipt date, editable.
- Payment status: Paid, Partially Paid, or Unpaid.
- Product/BOM line items.
- Grand total.
- Amount paid.
- Balance.
- Saved company bank details.

If the order has one BOM, use its product and service quantity. If it has multiple BOMs, each BOM is a receipt line. Generic names such as “Materials Service” are replaced by the available product/description for customer-facing output.

### 17.2 Receipt templates

Available templates:

1. Modern Dark.
2. Minimal Clean.
3. Elegant Botanical.

The default comes from Invoice Template Settings. A user may change the current receipt template without changing the global default.

### 17.3 Receipt actions

- Share/download PDF generated from the selected template.
- `Send Receipt` opens a payment-entry sheet. It asks for amount, payment method, and optional notes, generates a reference from the BOM/quotation/order, and records the payment through the order payment endpoint.
- Select receipt date.
- Use locally saved bank name, account name, account number, and bank code.

Order receipt data can be retrieved with `GET /api/orders/get-orders/{id}/receipt`.

The Send Receipt payment methods are Cash, Bank Transfer, POS, and Card. The current mobile implementation does not separately email the generated PDF from this button; its successful result means the payment was recorded. Preserve this behavior for exact parity, or rename the web action to `Record Payment & Issue Receipt` to make the operation explicit.

The generated file is named from the order number. On web, use a browser PDF download and Web Share API when available.

## 18. Invoice Workflow

### 18.1 Client Selection

**Entry:** Home > Generate Invoice.

**API:** `GET /api/sales/get-clients`.

- De-duplicate and sort clients.
- Search by client identity.
- Selecting a client opens a choice:
  - Generate Invoice from Quotation.
  - Open the client's existing Invoice List.

### 18.2 Choose Quotation

- Open Saved Client Quotations filtered to the selected client.
- Enable invoice mode.
- Selecting a quotation opens Invoice Preview.

### 18.3 Invoice Preview

Supports:

- A new invoice based on a quotation.
- An existing invoice opened from Invoice List/Database.

Display:

- Client details.
- Quotation/invoice number and dates.
- Product/BOM line items.
- Cost, selling, discount, final amount, amount paid, and balance as available.
- Selected template.
- Bank details.

Bank details are editable and persisted:

- Bank name.
- Account name.
- Account number.
- Bank code.

### 18.4 Invoice templates

Templates:

1. Modern Dark.
2. Minimal Clean.
3. Elegant Botanical.

Invoice Template Settings saves the default template. Invoice Preview may open the template selector and render a full A4 preview. The mobile implementation captures the selected widget and embeds it into a PDF; web should render print-quality HTML/CSS or PDF with equivalent content.

### 18.5 Create Invoice

**API:** multipart `POST /api/invoices/create`.

Payload includes:

- Quotation ID.
- Due date, defaulting to 30 days after creation unless changed.
- Notes/template metadata.
- Amount paid, initially zero in the direct creation flow.
- Optional generated invoice PDF.

On success, return to Dashboard/Home.

### 18.6 Invoice List

**API:** `GET /api/invoices/invoices`.

Cards show:

- Invoice/client identity.
- Status.
- Date/due date.
- Amount.
- Amount paid.
- Balance.

Tapping opens Invoice Preview for the existing invoice.

## 19. Database

**Entry:** Home > Database.

The Database screen is an eight-tab management console:

1. Quotations.
2. BOMs.
3. Clients.
4. Staff.
5. Products.
6. Materials.
7. Invoices.
8. Receipts.

All tabs require:

- Search.
- Loading/error/empty states.
- Refresh.
- Record cards or tables.
- Edit modal/drawer.
- Delete confirmation where deletion is supported.
- Refresh after mutation.

### 19.1 Database APIs

| Tab | Read | Update/action | Delete |
|---|---|---|---|
| Quotations | `GET /api/database/quotations` | `PUT /api/quotation/{id}` | `DELETE /api/quotation/{id}` |
| BOMs | `GET /api/database/boms` | `PUT /api/bom/{id}` | `DELETE /api/bom/{id}` |
| Clients | `GET /api/database/clients` | `PUT /api/database/clients` | `DELETE /api/database/clients` |
| Staff | `GET /api/database/staff` | `PUT /api/database/staff/{userId}` | `DELETE /api/auth/staff/{userId}` |
| Products | `GET /api/database/products` | `PUT /api/product/{id}` | `DELETE /api/product/{id}` |
| Materials | `GET /api/database/materials` and grouped endpoint | `PUT /api/database/materials/{id}` and pricing/type actions | `DELETE /api/database/materials/{id}` |
| Invoices | `GET /api/database/invoices` | Status and payment endpoints | `DELETE /api/invoices/invoices/{id}` |
| Receipts | `GET /api/database/receipts` | `PUT /api/database/receipts/{id}` | `DELETE /api/database/receipts/{id}` |

Invoice-specific actions:

- Status: `PUT /api/invoices/invoices/{id}/status`.
- Payment: `POST /api/invoices/{id}/payment`.

Material-specific behavior:

- Group by category/subcategory/type where returned.
- Edit price and material metadata.
- Update pricing/type through the database material pricing endpoint.
- Platform-owner state can expose additional controls.

## 20. Staff and Permissions

### 20.1 Staff Management

**API:** `GET /api/auth/staff`.

Capabilities:

- List and search staff.
- Show role, position, contact and access status.
- Open permissions.
- Revoke access.
- Restore access.
- Remove staff.

Endpoints:

- Revoke: `/api/auth/staff/{id}/revoke`.
- Restore: `/api/auth/staff/{id}/restore`.
- Remove: `DELETE /api/auth/staff/{id}`.

The company owner cannot be removed through the staff UI.

### 20.2 Invite Staff

**Fields:**

- Full name.
- Email.
- Phone.
- Role.
- Position.

Validate email and phone before submission.

**API:** `POST /api/auth/invite-staff`.

After invitation, resolve the created staff record and open permission configuration.

### 20.3 Staff Permissions

**API family:** `/api/permission/{staffId}` with GET, PUT, grant, and revoke operations exposed by the service.

Permission areas include:

- Quotations.
- Sales.
- Orders.
- Database.
- Receipts.
- Backup alerts.
- Invoices.
- Products.
- BOMs.

Web route guards and action visibility must enforce these permissions. Do not rely only on hiding buttons; API authorization errors must also be handled.

## 21. Settings

### 21.1 Settings home

Sections:

- Company Management.
- Business Settings.
- Company Settings.
- Guided Help.
- Logout.
- Platform Dashboard for platform owners.

Business links:

- Overhead Cost.
- Material Upload.
- Invoice Template.
- Live Chat Support.

### 21.2 Company settings

**API:**

- Read: `GET /api/settings`.
- Update: `PUT /api/settings`.

Controls:

- Cloud Sync.
- Auto Backup.
- Push Notification.
- Email Notification.
- Quotation Reminders.
- Project Deadlines.
- Backup Alerts.

Only owners and admins may change these values. Other users see disabled controls and an explanatory message.

Updates are optimistic on mobile: update the UI immediately, call the API, and restore the previous value plus show an error if the request fails.

### 21.3 Guided Help

- Local preference.
- Shows or hides help icons across key screens such as Quotations, Orders, BOMs, Sales, and Settings.
- Help opens concise contextual instructions without changing workflow state.

### 21.4 Live Chat

Open the embedded Tawk live-chat page. On web, integrate the same support provider in a contained support route or widget.

## 22. Platform Owner

Only show this module when the authenticated user is a platform owner.

### 22.1 Platform Dashboard

**API:** `GET /api/platform/dashboard/stats`.

Summary cards:

- Companies and active companies.
- Products and pending products.
- Orders.
- Platform users.

Actions:

- Analytics.
- Pending Materials.
- Create Global Material.
- Create Global Product.
- Material Updates.
- Companies.
- Products.

The dashboard is responsive: two columns on narrow layouts, three/four columns as space increases.

### 22.2 Companies

- List/search companies.
- Paginate.
- Open Company Details.
- Show company usage/profile/activity returned by platform endpoints.
- Company Details presents the company's users and operational/catalog data exposed by the service.

### 22.3 Products

- View all products.
- View pending products.
- Open product details.
- Approve or reject pending products.
- Create a global product.

Use the `/api/platform/...` product endpoints defined by `PlatformOwnerService`.

### 22.4 Pending Materials

- Load pending materials.
- Inspect full material metadata.
- Select one or multiple records.
- Approve or reject one.
- Bulk approve or reject selected records.
- Refresh counts and list after action.

### 22.5 Create Global Material

Choose a category and open its category-specific form:

- Board.
- Fabric.
- Foam.
- Hardware.
- Marble.
- Other.
- Wood.

Forms collect the category's dimensions, unit, variants/types, pricing, image and descriptive fields, then create a platform/global material through the material/platform API.

### 22.6 Material Updates

1. List companies.
2. Select a company.
3. Load that company's materials.
4. Search/filter materials.
5. Edit a company's material price directly.
6. Select and bulk-delete materials where supported.

This tool is distinct from approval: it manages already available company material data.

### 22.7 Platform Analytics

Present the platform overview and analytics response from `PlatformOwnerService`, including company, product, order, user, and activity metrics available from the API.

## 23. Core Data and Calculation Requirements

### 23.1 BOM totals

For each BOM:

- Material total = sum of authoritative material line totals.
- Additional-cost total = sum of additional cost amounts.
- Manufacturing overhead = amount allocated by overhead settings.
- Cost price depends on pricing Method 1 or Method 2.
- Markup amount = configured percentage applied to the method's cost base.
- Selling price = cost base plus markup.

For a quotation item:

- Item cost = BOM cost price multiplied by selected quantity.
- Item selling = BOM selling price multiplied by selected quantity.

For a quotation:

- Total cost = sum of item costs.
- Total selling = sum of item selling values.
- Discount amount is derived from the discount rule/field.
- Final total = total selling minus discount amount.

### 23.2 Order and payment totals

- Order total comes from the selected quotation/BOM selling total.
- Amount paid is cumulative.
- Balance = total amount minus amount paid.
- Paid when balance is zero or less.
- Partially Paid when amount paid is greater than zero and balance remains.
- Unpaid when amount paid is zero.

### 23.3 Data integrity

- Retain IDs for product, material, BOM, quotation, order, invoice, receipt, client, company and staff records.
- Do not infer a material's unit from its name.
- Do not show area inputs unless the selected API material unit is `sqm`.
- Preserve API-calculated area and billable units.
- Preserve imported BOM IDs and original pricing data.
- Re-fetch server state after create/update/delete rather than relying indefinitely on a mutated local copy.

## 24. Web Route Recommendation

The web frontend can use these route equivalents:

```text
/onboarding
/auth/sign-in
/auth/sign-up
/auth/forgot-password
/auth/verify-otp
/auth/reset-password
/companies/select
/companies/new
/home
/products/new
/products/:id/edit
/quotations
/quotations/new/client
/quotations/new/review
/quotations/:id
/boms/new/materials
/boms/new/summary
/boms/import
/orders
/orders/new/select-quotation
/orders/new/:quotationId
/sales
/sales/analytics
/orders/:id/receipt
/invoices/clients
/invoices
/invoices/:id
/database/:section
/settings
/settings/company
/settings/staff
/settings/overhead
/settings/materials
/settings/invoice-template
/settings/support
/platform
/platform/companies
/platform/products
/platform/materials/pending
/platform/materials/new
/platform/material-updates
/platform/analytics
```

Route naming may follow the web codebase's conventions, but navigation guards and workflow order must match the mobile behavior.

## 25. Web Acceptance Checklist

The web implementation is functionally equivalent when:

- Authentication, recovery, company selection, switching and logout work.
- All five primary sections preserve their purpose and major actions.
- Company-less users are correctly gated.
- Products and materials can be created, edited and selected.
- Material selector renders category, subcategory, unit and size/color from API data.
- Only `sqm` materials display length/width and use area calculation.
- Integer and float quantity rules match the unit table.
- A BOM can be created, priced, saved, imported and edited.
- Overhead method and markup produce the same values as mobile for the same inputs.
- One or more BOMs can become a client quotation.
- A quotation can become an order with per-BOM schedules.
- Orders support search, filters, status changes, assignment and deletion.
- Payments update received/outstanding totals and enforce balance limits.
- Receipts use all three templates and support PDF/share/send.
- Invoices can be created from client quotations, previewed, listed and managed.
- Database exposes all eight data sections and their edit/delete actions.
- Staff invitations, access revocation and feature permissions work.
- Company settings enforce owner/admin edit access.
- Material approval and platform-owner screens are unavailable to normal users.
- Every API screen has loading, error, empty, refresh and mutation feedback states.
- Responsive layouts retain the mobile information hierarchy and business workflow.

## 26. Implementation Note

This document describes the behavior currently implemented in the Flutter app, including a few legacy routes that coexist with newer flows. For web parity, implement the principal flows first:

1. Session/company.
2. Product/material.
3. BOM and overhead pricing.
4. Quotation.
5. Order.
6. Sales/payment/receipt.
7. Invoice.
8. Database, staff, settings and platform administration.

When an API response differs from a locally inferred value, use the API's IDs, status, pricing totals, calculation metadata and authorization result as authoritative.

## 27. Screen Inventory

This inventory maps every page-level mobile file to the web behavior described above. Widgets such as cards, selectors, bottom sheets, and invoice templates are included in their owning screen sections rather than treated as standalone routes.

| Mobile file/screen | Web equivalent | Specification section |
|---|---|---|
| `session_gate.dart` | Session bootstrap/route guard | 3.1 |
| `Onboarding.dart` | Onboarding carousel | 3.2 |
| `Signup.dart` | Sign Up | 3.3 |
| `Signin.dart` | Sign In | 3.4 |
| `resetHome.dart` | Forgot Password | 3.5 |
| `ResetPassword.dart` | OTP verification | 3.5 |
| `updatePassword.dart` | Set New Password | 3.5 |
| `Selector.dart` | Company Selection | 4.1 |
| `addCompany.dart` | Create/Edit Company | 4.2-4.3 |
| `Home.dart` | Home Dashboard | 5 |
| `Notification.dart` | Notifications | 6 |
| `addProduct.dart` | Add/Edit Product | 7.1 |
| `existingProduct.dart` | Existing Product Picker | 7.2 |
| `selectCategory.dart` | Company Material Create/Edit | 9 |
| `catalog_material_picker.dart` | Saved Catalog Material Picker | 9 |
| `CreateBoard.dart` | Legacy/category Board material form | 9 |
| `CreateWood.dart` | Legacy/category Wood material form | 9 |
| `CreateFoam.dart` | Legacy/category Foam material form | 9 |
| `CreateMarble.dart` | Legacy/category Marble material form | 9 |
| `CreateFabric.dart` | Legacy/category Fabric, Hardware, and Other forms | 9 |
| `Quotations.dart` | Working BOM/Quotation Workspace | 10.1 |
| `AddMaterial.dart` | Add Materials and Other Costs | 10.3-10.4 |
| `BomList.dart` | BOM Draft Item List | 10.3 |
| `ImportBom.dart` | Legacy Multi-Quotation/BOM Import | 10.5 |
| `BomSummary.dart` | BOM Pricing and Save | 11 |
| `QuoteSummary.dart` | Legacy Local Quotation Summary | 10-12 |
| `FirstQuote.dart` | Client Details | 12.1 |
| `SecQuote.dart` | Quotation Review/Submit | 12.2-12.3 |
| `AllclientQuotations.dart` | Saved/Client Quotations | 13 |
| `AddOverhead.dart` | Overhead Cost Management | 14 |
| `QuoforOrder.dart` | Select Quotation for Order | 15.1 |
| `Orderpreview.dart` | Order Preview and Scheduling | 15.2 |
| `allOrders.dart` | Order List | 15.3-15.6 |
| `salesHome.dart` | Sales Dashboard | 16.1-16.2 |
| `SalesAnalytics.dart` | Sales Analytics | 16.3 |
| `PaymentRecipt.dart` | Receipt Preview/Payment Issue | 17 |
| `clients_home.dart` | Invoice Client Picker | 18.1 |
| `invoice_preview.dart` | Invoice Preview/Create | 18.3-18.5 |
| `invoice_template_settings.dart` | Default Invoice Template | 18.4 |
| `invoiceList.dart` | Client Invoice List | 18.6 |
| `invoiceDetail.dart` | Legacy Invoice Detail | 18.3 and 18.6 |
| `database_home.dart` | Eight-tab Database Console | 19 |
| `manage.dart` | Staff Management | 20.1 |
| `addStaff.dart` | Invite Staff | 20.2 |
| `StaffPermission.dart` | Staff Permissions | 20.3 |
| `settings.dart` | Settings Home | 21 |
| `tawk_live_chat.dart` | Live Chat Support | 21.4 |
| `platform_dashboard_new.dart` | Platform Dashboard | 22.1 |
| `all_companies.dart` | Platform Companies | 22.2 |
| `company_details.dart` | Platform Company Details | 22.2 |
| `all_products_view.dart` | Platform Products | 22.3 |
| `pending_products.dart` | Pending Product Approval | 22.3 |
| `create_global_product.dart` | Create Global Product | 22.3 |
| `pending_materials.dart` | Pending Material Approval | 22.4 |
| `create_global_material.dart` | Global Material Category Picker | 22.5 |
| `create_global_*_material.dart` | Seven Global Material Forms | 22.5 |
| `material_updates.dart` | Company Material Updates | 22.6 |
| `platform_analytics.dart` | Platform Analytics | 22.7 |
