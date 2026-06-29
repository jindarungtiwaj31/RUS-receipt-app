# ตั้งค่าระบบใช้งานจริงด้วย Supabase

คู่มือนี้ใช้สำหรับเปลี่ยนเว็บจากการเก็บข้อมูลใน Browser ให้เป็นฐานข้อมูลกลางที่หลายคนใช้งานร่วมกันได้

## 1. สร้าง Supabase Project

1. เข้า https://supabase.com
2. สร้าง Project ใหม่
3. ตั้ง Database Password และเก็บไว้ให้ดี
4. รอให้ Project สร้างเสร็จ

## 2. สร้างฐานข้อมูล

1. เข้าเมนู `SQL Editor`
2. เปิดไฟล์ `supabase/schema.sql`
3. คัดลอก SQL ทั้งหมดไปวาง
4. กด `Run`

สิ่งที่จะถูกสร้าง:

- ตาราง `app_state` สำหรับเก็บข้อมูลระบบกลาง
- ตาราง `profiles` สำหรับกำหนดสิทธิ์ Admin/User
- ฟังก์ชัน `issue_receipt` สำหรับออกเลขใบเสร็จแบบกันเลขซ้ำ
- ฟังก์ชัน `cancel_receipt` สำหรับยกเลิกใบเสร็จในฐานข้อมูลกลาง
- Row Level Security สำหรับให้เฉพาะผู้ที่ Login แล้วเข้าถึงข้อมูล

## 3. สร้างบัญชีผู้ใช้งาน

1. ไปที่ `Authentication`
2. เลือก `Users`
3. กด `Add user`
4. ใส่อีเมลและรหัสผ่าน
5. สร้างบัญชี Admin อย่างน้อย 1 คน และ User ตามจำนวนผู้ใช้งานจริง

## 4. กำหนดสิทธิ์ในตาราง profiles

หลังสร้าง user แล้ว ให้คัดลอก `User UID` ของแต่ละคนจากหน้า Authentication แล้วเพิ่มข้อมูลใน SQL Editor:

```sql
insert into public.profiles (user_id, role, display_name, staff_code)
values
  ('USER_UID_ADMIN', 'admin', 'ชื่อผู้ดูแลระบบ', 'A001'),
  ('USER_UID_USER', 'user', 'ชื่อเจ้าหน้าที่ออกใบเสร็จ', '1001');
```

เปลี่ยน `USER_UID_ADMIN` และ `USER_UID_USER` เป็น UID จริงจาก Supabase

## 5. ใส่ค่าเชื่อมต่อในเว็บ

1. ไปที่ `Project Settings`
2. เลือก `API`
3. คัดลอก `Project URL`
4. คัดลอก `anon public key`
5. เปิดไฟล์ `supabase-config.js`
6. ใส่ค่าแบบนี้:

```js
window.RECEIPT_APP_SUPABASE = {
  url: "https://YOUR_PROJECT_ID.supabase.co",
  anonKey: "YOUR_ANON_PUBLIC_KEY"
};
```

ห้ามใส่ `service_role key` ลงในเว็บเด็ดขาด

## 6. ส่งขึ้น GitHub Pages

หลังแก้ `supabase-config.js` แล้ว ใช้คำสั่ง:

```bash
git add index.html supabase-config.js supabase/schema.sql SUPABASE_SETUP.md README.md
git commit -m "Enable Supabase central database"
git push origin main
```

จากนั้นเปิดเว็บ GitHub Pages เดิม

## วิธีใช้งานหลังเปิด Supabase

- Admin เข้าระบบด้วยอีเมล/รหัสผ่านจาก Supabase
- User เข้าระบบด้วยอีเมล/รหัสผ่านจาก Supabase
- ข้อมูลใบเสร็จ เล่มใบเสร็จ รายงาน และรายการตั้งต้นจะใช้ฐานข้อมูลกลางร่วมกัน
- เลขใบเสร็จออกผ่านฟังก์ชัน `issue_receipt` ในฐานข้อมูล จึงลดความเสี่ยงเลขซ้ำเมื่อหลายคนใช้งานพร้อมกัน

## ข้อควรระวัง

- `anon public key` ใช้ได้ในเว็บตามปกติ แต่ `service_role key` ต้องห้ามเผยแพร่
- ให้สร้างบัญชีเฉพาะเจ้าหน้าที่จริงเท่านั้น
- หากต้องการความปลอดภัยระดับสูงกว่าเดิม เช่น จำกัดสิทธิ์รายเมนูแบบเข้มงวด ควรแยกข้อมูลจาก `app_state` เป็นตารางเฉพาะแต่ละส่วนและเพิ่ม Policy รายตาราง
