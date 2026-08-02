import AppRoutes from "./routes/AppRoutes";
import AppErrorBoundary from "./components/common/AppErrorBoundary";
import SessionBootstrap from "./components/SessionBootstrap";

export default function App() {
  return (
    <AppErrorBoundary>
      <SessionBootstrap>
        <AppRoutes />
      </SessionBootstrap>
    </AppErrorBoundary>
  );
}
