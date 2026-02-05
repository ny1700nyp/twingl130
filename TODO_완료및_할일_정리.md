# 작업 진행 현황 & 직접 하실 일

## ✅ 이미 완료된 작업 (코드/SQL 파일 반영됨)

### 1. user_type 마이그레이션 (trainer/trainee → tutor/student/tudent)
- **DB 마이그레이션 SQL**  
  - `MIGRATE_USER_TYPE_TUTOR_STUDENT.sql` 생성  
  - 기존 `trainer` → `tutor`, `trainee` → `student` 로 업데이트  
  - CHECK 제약: `user_type IN ('tutor', 'student', 'tudent')`
- **앱 코드 전반**  
  - `user_type` 비교/저장을 모두 **tutor / student / tudent** 기준으로 수정  
  - 온보딩, 홈, 프로필, 매칭, agreement 등 해당 부분 반영 완료
- **RPC용 SQL**  
  - `CREATE_NEARBY_PROFILES_FUNCTION.sql`: `user_type IN ('tutor', 'tudent')`  
  - `CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql`: 동일

### 2. 메인 화면·매칭 로직 리팩터 (User Type / Matching Rules)
- **규칙**  
  - 매칭: **내 Goals ↔ 상대 Talents** (튜터 찾기), **내 Talents ↔ 상대 Goals** (학생 후보), **내 Talents ↔ 상대 Talents** (다른 트레이너)
- **SupabaseService**  
  - `getProfileGoals` / `getProfileTalents` / `getEffectiveUserType` / `isTudentProfile`  
  - `getNearbyTutorsForStudent`, `getNearbyTrainersForTutor`, `getNearbyStudentsForTutor`  
  - `getTalentMatchingCards` ([The Perfect Tutors, Anywhere] 전용, RPC)
- **HomeScreen**  
  - Student: "Meet Tutors in your area", "The Perfect Tutors, Anywhere"  
  - Tutor: "Other Trainers in the area", "Student Candidates in the area"  
  - Tudent: 위 3개 섹션 모두
- **FindNearbyTalentScreen**  
  - `FindNearbySection`: meetTutors / otherTrainers / studentCandidates  
  - 섹션별로 위 API 호출
- **GlobalTalentMatchingScreen**  
  - 내 Goals ↔ 타겟 Talents, limit 20

### 3. 더미 프로필
- 더미는 **Student만** 생성 (초기·재생성 모두)
- 더미 프로필에 **GPS 필수**: 실기기 위치 시도 후 실패 시 fallback 좌표(서울) 설정

---

## 🔲 직접 하셔야 할 일

### 1. DB에서 마이그레이션 실행 (필수)
1. **Supabase SQL Editor**에서 아래 파일 내용을 **순서대로** 실행하세요.  
   - `MIGRATE_USER_TYPE_TUTOR_STUDENT.sql`
2. 실행 후 확인:
   - `SELECT DISTINCT user_type FROM profiles;`  
     → `tutor`, `student`, (필요 시) `tudent` 만 나와야 합니다.
3. **CHECK 제약**이 이미 있어서 오류가 나면:
   - 2)번 블록(DO $$ ... END $$; 및 ADD CONSTRAINT)만 건너뛰거나,
   - 기존 제약 이름을 확인한 뒤, 해당 이름으로 `DROP CONSTRAINT` 후 다시 `ADD CONSTRAINT` 하세요.

### 2. RPC 함수 재생성 (사용 중이면 필수)
앱에서 **거리 기반 nearby** 호출 시 `get_nearby_profiles` RPC를 쓰고 있으면,  
`user_type` 값을 새 규칙에 맞추기 위해 **함수를 한 번 재생성**해야 합니다.

1. Supabase SQL Editor에서 **아래 파일 전체**를 실행:
   - `CREATE_NEARBY_PROFILES_FUNCTION.sql`
2. Talent matching용 RPC를 쓰고 있다면:
   - `CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql` 도 동일하게 실행

(이미 같은 내용으로 배포되어 있으면 생략 가능)

### 3. 앱 빌드·실기 테스트
1. `flutter pub get` 후 **앱 빌드** (에러 없는지 확인)
2. **온보딩**  
   - Tutor / Student 선택 후 저장 → DB에 `user_type = 'tutor'` 또는 `'student'` 로 들어가는지 확인
3. **홈**  
   - Student로 로그인 → "Meet Tutors in your area", "The Perfect Tutors, Anywhere" 노출  
   - Tutor로 로그인 → "Other Trainers in the area", "Student Candidates in the area" 노출  
   - Tudent면 위 3개 모두 노출되는지 확인
4. **더미**  
   - 더미 생성 시 Student만 생성되는지, 프로필에 위도/경도가 채워지는지 확인

### 4. (선택) Tudent 지원
- **DB**  
  - Tudent는 `user_type = 'tudent'` + 선택적으로 `goals` 컬럼.  
  - `goals` 컬럼이 없으면 코드는 `talents` 등으로 fallback 처리해 둔 상태입니다.
- **온보딩**  
  - 현재는 Tutor / Student 두 가지만 선택 가능.  
  - "Tutor & Student 둘 다(Tudent)" 옵션을 추가하려면 온보딩 UI에 세 번째 세그먼트(또는 체크)를 넣고, 저장 시 `user_type = 'tudent'` 로 넣도록 수정하면 됩니다.

### 5. (선택) 약관 타입 DB 값
- 앱에서는 **tutor/student** 로만 넘기고,  
  DB `user_agreements.agreement_type` 은 **`trainer_terms`**, **`trainee_waiver`** 그대로 사용 중입니다.
- DB 컬럼 값까지 **tutor_terms** / **student_waiver** 로 바꾸려면:
  - 기존 데이터 마이그레이션용 UPDATE SQL 작성
  - 앱에서 `saveUserAgreement` / `hasUserAgreed` 호출 시 넘기는 문자열을 `tutor_terms` / `student_waiver` 로 변경  
  지금은 **기존 DB와 호환**되도록 그대로 두었습니다.

---

## 체크리스트 (복사해서 사용 가능)

- [ ] `MIGRATE_USER_TYPE_TUTOR_STUDENT.sql` 실행
- [ ] `SELECT DISTINCT user_type FROM profiles;` 로 tutor/student(, tudent) 확인
- [ ] (RPC 사용 시) `CREATE_NEARBY_PROFILES_FUNCTION.sql` 실행
- [ ] (RPC 사용 시) `CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql` 실행
- [ ] 앱 빌드 성공
- [ ] 온보딩 Tutor/Student 저장 후 DB user_type 확인
- [ ] 홈에서 Student/Tutor별 섹션 노출 확인
- [ ] 더미 생성 시 Student만 생성·GPS 포함 여부 확인
