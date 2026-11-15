# CloudOps Console UI References & Design Specification

### 1. Visual Design Principles
- **Inspiration**: Microsoft Azure Portal / Microsoft 365 Admin Center
- **Color Palette**:
  - Primary / Brand: `#0078D4` (Azure Blue)
  - Primary Hover: `#106EBE`
  - Dark Neutral / Text: `#242424` (Primary typography)
  - Secondary Text: `#616161`
  - Background: `#F5F5F5` (Light neutral grey)
  - Surface / Cards: `#FFFFFF` (Pure white)
  - Border / Dividers: `#E0E0E0`
  - Success: `#107C41` (Green)
  - Warning: `#D83B01` (Amber/Orange)
  - Danger / Error: `#A80000` (Crimson)
  - Tainted Resource Accent: `#8A3B00` (Burnt Orange / Warning Badge)
- **Typography**: Segoe UI, -apple-system, BlinkMacSystemFont, "Roboto", sans-serif.

### 2. Layout Structure
- **Global Header**: CloudOps branding, cluster status indicator (`lab-eval12 - Active`), active context, user profile.
- **Collapsible Sidebar**:
  - Overview / Dashboard
  - Cluster & Nodes (Shows labels, taints, capacity)
  - Workloads & Pods (Shows node placement, replica counts)
  - Deployments (Shows desired vs ready, scaling controls)
  - Storage & PVCs (PostgreSQL persistent volume status)
  - Scheduling Lab (Live interactive viewer for Taints & Tolerations experiments)
  - Events & Logs (Kubernetes system events)
- **Content Area**: Breadcrumb navigation, command bar with action buttons, tabular grids with clean borders, and real-time metric cards.
