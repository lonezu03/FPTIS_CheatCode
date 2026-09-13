# Web FitTrack

## Công nghệ và vị trí source

- React 19, TypeScript, Vite và React Router.
- TanStack Query cho server state, Zustand cho trạng thái phiên.
- React Hook Form/Zod, Tailwind CSS, Recharts, Sonner và Lucide.

Source web nằm tại `frontend/fittrack-frontend/`. Vercel build từ
`frontend/`; script `frontend/build-vercel.mjs` build ứng dụng con rồi đưa kết
quả vào `frontend/dist/`.

```powershell
cd frontend\fittrack-frontend
npm ci
npm run dev
```

## API và phiên đăng nhập

Mọi request đi qua shared client `src/api/axios.ts`:

- local mặc định gọi backend Docker tại `http://localhost:8082/api`;
- production Vercel dùng `/api` cùng origin rồi rewrite tới Render;
- `withCredentials=true` cho cookie xác thực;
- request thay đổi dữ liệu gửi `X-Requested-With`;
- access token chỉ được giữ trong memory và tự làm mới bằng refresh cookie;
- `localStorage` chỉ giữ bản sao thông tin hiển thị của user, không giữ access
  hoặc refresh token.

Shared client theo dõi mọi request. Read hiển thị progress không chặn màn hình;
write chặn tương tác trong lúc xử lý và từ chối một request thay đổi giống hệt
đang chạy đồng thời.

Không đưa secret hoặc backend credential vào biến `VITE_*`; mọi giá trị này đều
có thể đọc được từ browser bundle.

## Route và phân quyền

- `ProtectedRoute` khôi phục phiên qua refresh cookie.
- `FeatureRoute` kiểm soát điều hướng theo permission được backend trả về.
- `AdminRoute` bảo vệ màn hình quản trị ở client.
- Backend vẫn là nơi bắt buộc thực thi authorization.

Các nhóm route hiện tại gồm Đặt cơm, Luyện tập, Sức khỏe/Dinh dưỡng, Việc cần
làm, Thời khóa biểu, Kho câu nói, Hồ sơ và các màn hình quản trị.

Vercel rewrite mọi route không phải `/api` về `index.html`, vì vậy refresh trực
tiếp `/foods`, `/workouts`, `/schedule` hoặc route SPA khác không được trả 404.

## Kiểm tra trước deploy

```powershell
cd frontend\fittrack-frontend
npm run lint
npm test
npm run build
npm run test:e2e
```

Xem thêm [ARCHITECTURE.md](ARCHITECTURE.md), [DEPLOYMENT.md](DEPLOYMENT.md) và
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
