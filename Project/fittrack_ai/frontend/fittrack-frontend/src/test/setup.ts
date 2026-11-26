import "@testing-library/jest-dom/vitest";
import { configure } from "@testing-library/react";

// Lần chạy đầu (cache transform nguội, nhiều worker jsdom song song) có thể làm trang nặng
// render chậm hơn 1 giây mặc định của findBy/waitFor và gây lỗi ngẫu nhiên. Nới thời gian chờ
// để kết quả không phụ thuộc tải máy; test đúng vẫn kết thúc ngay khi điều kiện thỏa.
configure({ asyncUtilTimeout: 4000 });
