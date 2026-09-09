import AppRoutes from "./routes/AppRoutes";
import AppErrorBoundary from "./components/common/AppErrorBoundary";
import ApiActivityOverlay from "./components/common/ApiActivityOverlay";
import SessionBootstrap from "./components/SessionBootstrap";

export default function App() {
  return (
    <AppErrorBoundary>
      <>
        <SessionBootstrap>
          <AppRoutes />
        </SessionBootstrap>
        <ApiActivityOverlay />
      </>
    </AppErrorBoundary>
  );
}
