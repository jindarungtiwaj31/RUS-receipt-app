# ระบบออกใบเสร็จรับเงิน

แพ็กนี้พร้อมนำขึ้น GitHub Pages แบบ Static Website

โปรเจกต์นี้เป็นเว็บ HTML/CSS/JavaScript แบบไฟล์เดียว ไม่มี `package.json` และไม่มี dependencies ที่ต้องติดตั้ง

## ไฟล์ที่ต้องอัปโหลดขึ้น GitHub

- `index.html`
- โฟลเดอร์ `assets`
- `supabase-config.js`
- `SUPABASE_SETUP.md`
- โฟลเดอร์ `supabase`
- `.nojekyll`
- `.gitignore`

ให้อัปโหลดไฟล์เหล่านี้ไว้ที่หน้าแรกของ Repository หรือใช้โฟลเดอร์นี้ทั้งโฟลเดอร์เป็นต้นทางของ Repository

## วิธีรันในเครื่อง

เปิดไฟล์ `index.html` ใน Browser ได้โดยตรง หรือใช้ web server ง่าย ๆ:

```bash
python3 -m http.server 8080
```

แล้วเปิด `http://localhost:8080`

## วิธีเผยแพร่ด้วย GitHub Pages แบบ Deploy from branch

1. เข้า GitHub แล้วสร้าง Repository ใหม่ เช่น `receipt-app`
2. อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้ขึ้น Repository หรือ push ด้วย Git
3. เข้าเมนู `Settings`
4. เลือก `Pages`
5. ที่ `Build and deployment` เลือก `Deploy from a branch`
6. ที่ `Branch` เลือก `main` และโฟลเดอร์ `/root`
7. กด `Save`
8. รอประมาณ 1-3 นาที แล้วเปิด URL ที่ GitHub Pages แสดงให้

## คำสั่ง Git สำหรับ repo ใหม่

หลังสร้าง Repository บน GitHub แล้ว ใช้คำสั่งนี้ในโฟลเดอร์โปรเจกต์:

```bash
git remote add origin https://github.com/YOUR_USERNAME/receipt-app.git
git branch -M main
git push -u origin main
```

เปลี่ยน `YOUR_USERNAME/receipt-app` ให้เป็นชื่อ Repository จริงของคุณ

## ข้อสำคัญก่อนใช้งานจริง

เว็บชุดนี้เปิดได้ 2 โหมด:

1. โหมดปกติ: ไม่ใส่ค่า Supabase ใน `supabase-config.js` ข้อมูลจะถูกเก็บใน Browser ของผู้ใช้งานผ่าน `localStorage`
2. โหมดใช้งานจริงหลายคน: ใส่ค่า Supabase ใน `supabase-config.js` แล้วข้อมูลจะใช้ฐานข้อมูลกลางและ Login ผ่าน Supabase Auth

ถ้ายังใช้โหมดปกติ ผลคือ:

- ถ้าผู้ใช้คนละเครื่อง ข้อมูลใบเสร็จจะไม่ใช่ฐานข้อมูลเดียวกัน
- ถ้าล้างข้อมูล Browser ข้อมูลใบเสร็จในเครื่องนั้นอาจหาย
- ไม่มีบัญชี Admin ตัวอย่างในหน้าเว็บ ผู้ดูแลต้องตั้ง Username และ Password เองเมื่อเข้าใช้งานครั้งแรก
- เว็บ Static ยังไม่ใช่ระบบรักษาความปลอดภัยเต็มรูปแบบ เพราะโค้ดทั้งหมดอยู่ฝั่ง Browser

ถ้าต้องการให้หลายคนใช้ระบบเดียวกันจริง ให้ทำตามไฟล์ `SUPABASE_SETUP.md`

## Supabase Mode

ไฟล์ที่เกี่ยวข้อง:

- `supabase/schema.sql` ใช้สร้างฐานข้อมูลกลาง ตารางสิทธิ์ และฟังก์ชันออกเลขใบเสร็จ
- `supabase-config.js` ใช้ใส่ Project URL และ anon public key
- `SUPABASE_SETUP.md` คู่มือตั้งค่าทีละขั้น

เมื่อใส่ค่า Supabase แล้ว:

- Admin และ User จะ Login ด้วยอีเมล/รหัสผ่านจาก Supabase
- ข้อมูลใบเสร็จและรายงานใช้ฐานข้อมูลกลางร่วมกัน
- การออกเลขใบเสร็จจะทำผ่านฐานข้อมูลเพื่อลดความเสี่ยงเลขซ้ำเมื่อหลายคนใช้งานพร้อมกัน
