app:
  description: Production-oriented reusable AI receptionist Chatflow for Dify 1.16.1.
    Uses one conversational LLM, deterministic routing/normalization, an authenticated
    HTTP backend, safe response parsing, failure handling, business-time context,
    conversation memory, and starter questions.
  icon: 🤖
  icon_background: '#FFEAD5'
  icon_type: emoji
  mode: advanced-chat
  name: v1.1
  use_icon_as_answer_icon: false
dependencies:
- current_identifier: null
  type: marketplace
  value:
    marketplace_plugin_unique_identifier: langgenius/openrouter:0.1.7@b7042a30570e7c308016cdda45a3b1ee2fa91aa42c8d4a4587b304d769415363
    version: null
kind: app
version: 0.7.0
workflow:
  conversation_variables: []
  environment_variables:
  - description: 'Public backend origin only, without /api/ai/chat. Example: https://api.example.com'
    id: backend-base-url
    name: BACKEND_BASE_URL
    selector:
    - env
    - BACKEND_BASE_URL
    value: ''
    value_type: string
  - description: Bearer JWT accepted by the backend auth middleware for this client.
    id: backend-auth-token
    name: JWT_BEARER
    selector:
    - env
    - JWT_BEARER
    value: ''
    value_type: secret
  - description: Client-specific clinic name injected by the deployment backend.
    id: clinic-name
    name: clinic_name
    selector: [env, clinic_name]
    value: ''
    value_type: string
  - description: Client-specific owner name injected by the deployment backend.
    id: owner-name
    name: owner_name
    selector: [env, owner_name]
    value: ''
    value_type: string
  - description: Client-specific business hours injected by the deployment backend.
    id: business-hours
    name: business_hours
    selector: [env, business_hours]
    value: ''
    value_type: string
  - description: Client-specific address injected by the deployment backend.
    id: address
    name: address
    selector: [env, address]
    value: ''
    value_type: string
  - description: Client-specific phone injected by the deployment backend.
    id: phone
    name: phone
    selector: [env, phone]
    value: ''
    value_type: string
  - description: Client-specific email injected by the deployment backend.
    id: email
    name: email
    selector: [env, email]
    value: ''
    value_type: string
  - description: Client-specific services injected by the deployment backend.
    id: services
    name: services
    selector: [env, services]
    value: ''
    value_type: string
  - description: Client-specific FAQ injected by the deployment backend.
    id: faq
    name: faq
    selector: [env, faq]
    value: ''
    value_type: string
  - description: 'IANA timezone used to interpret today, tomorrow, weekdays, and relative
      times. Example: Asia/Kolkata.'
    id: business-timezone
    name: BUSINESS_TIMEZONE
    selector:
    - env
    - BUSINESS_TIMEZONE
    value: Asia/Kolkata
    value_type: string
  features:
    file_upload:
      allowed_file_extensions:
      - .JPG
      - .JPEG
      - .PNG
      - .WEBP
      allowed_file_types:
      - image
      allowed_file_upload_methods:
      - local_file
      - remote_url
      enabled: true
      fileUploadConfig:
        attachment_image_file_size_limit: 2
        audio_file_size_limit: 50
        batch_count_limit: 5
        file_size_limit: 15
        file_upload_limit: 50
        image_file_batch_limit: 10
        image_file_size_limit: 10
        knowledge_file_size_limit: 15
        single_chunk_attachment_limit: 10
        skill_file_size_limit: 50
        video_file_size_limit: 100
        workflow_file_upload_limit: 10
      image:
        enabled: true
        number_limits: 3
        transfer_methods:
        - local_file
        - remote_url
      number_limits: 3
    opening_statement: Hi! 👋 I'm your AI receptionist. I can help with services, prices,
      appointments, availability, cancellations, rescheduling, and general questions.
      How can I help you today?
    retriever_resource:
      enabled: true
    sensitive_word_avoidance:
      enabled: false
    speech_to_text:
      enabled: false
    suggested_questions:
    - What services do you offer?
    - How much does a haircut cost?
    - I want to book an appointment.
    - Can you check appointment availability?
    - I need to reschedule an appointment.
    - I want to cancel an appointment.
    suggested_questions_after_answer:
      enabled: false
    text_to_speech:
      enabled: false
      language: ''
      voice: ''
  graph:
    edges:
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: start
        targetType: code
      id: start-business_clock
      source: start
      sourceHandle: source
      target: business_clock
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: code
        targetType: llm
      id: business_clock-receptionist_llm
      source: business_clock
      sourceHandle: source
      target: receptionist_llm
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: llm
        targetType: code
      id: receptionist_llm-route_request
      source: receptionist_llm
      sourceHandle: source
      target: route_request
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: code
        targetType: if-else
      id: route_request-route
      source: route_request
      sourceHandle: source
      target: route
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: answer
      id: route-direct_answer
      source: route
      sourceHandle: 'false'
      target: direct_answer
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: http-request
      id: route-backend_request
      source: route
      sourceHandle: 'true'
      target: backend_request
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: http-request
        targetType: code
      id: backend_request-response_format
      source: backend_request
      sourceHandle: source
      target: response_format
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: code
        targetType: if-else
      id: backend_response-final_answer
      source: response_format
      sourceHandle: source
      target: response_route
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: http-request
        targetType: code
      id: backend_request-backend_failure
      source: backend_request
      sourceHandle: fail
      target: backend_failure
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: code
        targetType: answer
      id: backend_failure-failure_answer
      source: backend_failure
      sourceHandle: source
      target: failure_answer
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: http-request
      id: route-backend-backend_request-target
      source: route
      sourceHandle: backend
      target: backend_request
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: http-request
        targetType: code
      id: backend_request-fail-branch-backend_failure-target
      source: backend_request
      sourceHandle: fail-branch
      target: backend_failure
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: answer
      id: response_route-book_success
      source: response_route
      sourceHandle: book
      target: final_answer
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: answer
      id: response_route-cancel_success
      source: response_route
      sourceHandle: cancel
      target: cancel_success
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: answer
      id: response_route-reschedule_success
      source: response_route
      sourceHandle: reschedule
      target: reschedule_success
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        isInLoop: false
        sourceType: if-else
        targetType: answer
      id: response_route-default
      source: response_route
      sourceHandle: 'false'
      target: final_answer
      targetHandle: target
      type: custom
      zIndex: 0
    nodes:
    - data:
        desc: ''
        selected: false
        title: User Input
        type: start
        variables:
        - label: image
          max_length: 48
          options: []
          required: false
          type: file
          variable: image
      height: 72
      id: start
      position:
        x: 0
        y: 163.14285714285714
      positionAbsolute:
        x: 0
        y: 163.14285714285714
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        code: "\nfrom datetime import datetime, timezone as dt_timezone\ntry:\n  \
          \  from zoneinfo import ZoneInfo\nexcept Exception:\n    ZoneInfo = None\n\
          \ndef main(timezone_name: str = \"Asia/Kolkata\") -> dict:\n    tz_name\
          \ = str(timezone_name or \"Asia/Kolkata\").strip() or \"Asia/Kolkata\"\n\
          \n    try:\n        if ZoneInfo is not None:\n            tz = ZoneInfo(tz_name)\n\
          \            now = datetime.now(tz)\n        else:\n            now = datetime.now(dt_timezone.utc)\n\
          \            tz_name = \"UTC\"\n    except Exception:\n        now = datetime.now(dt_timezone.utc)\n\
          \        tz_name = \"UTC\"\n\n    return {\n        \"timezone\": tz_name,\n\
          \        \"current_date\": now.strftime(\"%Y-%m-%d\"),\n        \"current_time\"\
          : now.strftime(\"%H:%M\"),\n        \"current_datetime\": now.strftime(\"\
          %Y-%m-%d %H:%M\"),\n    }\n"
        code_language: python3
        desc: Creates the current business-local date/time context used for relative
          dates and times.
        outputs:
          current_date:
            children: null
            type: string
          current_datetime:
            children: null
            type: string
          current_time:
            children: null
            type: string
          timezone:
            children: null
            type: string
        selected: false
        title: Business Date & Time
        type: code
        variables:
        - value_selector:
          - env
          - BUSINESS_TIMEZONE
          variable: timezone_name
      height: 111
      id: business_clock
      position:
        x: 342
        y: 155.64285714285714
      positionAbsolute:
        x: 342
        y: 155.64285714285714
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        context:
          enabled: false
          variable_selector: []
        memory:
          query_prompt_template: '{{#sys.query#}}'
          role_prefix:
            assistant: ''
            user: ''
          window:
            enabled: true
            size: 20
        model:
          completion_params:
            max_tokens: 1024
            temperature: 0.3
          mode: chat
          name: google/gemini-3.5-flash
          provider: langgenius/openrouter/openrouter
        prompt_template:
        - id: bfb784d8-946d-4292-b40d-3df6d0f4442d
          role: system
          text: 'You are the master AI receptionist for a real business.


            Your job is to be warm, natural, accurate, and useful while protecting
            the business system from bad or duplicate requests.


            You have two output modes. Return exactly ONE line beginning with either:

            DIRECT:

            or

            BACKEND:


            CURRENT BUSINESS TIME

            Timezone: {{#business_clock.timezone#}}

            Current date: {{#business_clock.current_date#}}

            Current time: {{#business_clock.current_time#}}

            Current local date/time: {{#business_clock.current_datetime#}}


            RELATIVE DATE/TIME RULES

            Use the current business-local date/time above as the reference.

            Understand ordinary human expressions, including:

            - today

            - tomorrow

            - yesterday

            - day after tomorrow

            - this/next Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

            - "in 2 days"

            - "in 3 hours"

            - "2 hours later"

            - "30 minutes later"

            - "in 45 minutes"

            - "at 3 PM", "at 2 pm", "9:30 AM", "17:30"

            - explicit dates such as August 15, 2026 or 15 August

            - dates without a year, using the next appropriate occurrence

            Convert dates to YYYY-MM-DD and appointment times to 24-hour HH:mm when
            sending a BACKEND request.


            Do not guess a missing date or time. Ask for it through the backend by
            sending the information you have. Never claim availability or a booking
            yourself.


            CONVERSATION MEMORY — CRITICAL

            Use the entire conversation history, not only the customer''s newest sentence.


            Whenever a customer gives information over multiple turns, create a SELF-CONTAINED
            backend request containing ALL relevant facts already established in the
            conversation plus the newest change.


            This is mandatory for BOOKING, AVAILABILITY, CANCELLATION, and RESCHEDULING.


            IMPORTANT CONTINUITY RULE:

            If an appointment was just discussed or successfully booked, remember
            its:

            - customer name

            - customer phone

            - customer email, if provided

            - service

            - appointment date

            - appointment time


            If the customer later says "cancel it", "cancel my appointment", "reschedule
            it", "move it", "change the time", "same appointment", or similar, DO
            NOT send only the newest sentence. Reconstruct the request using the appointment
            details from the conversation.


            CANCELLATION REQUIREMENT:

            Your BACKEND cancellation request MUST contain at least:

            - customer name OR customer phone OR customer email

            - appointment date

            - appointment time


            If the conversation contains those details, ALWAYS include them.

            Example:

            BACKEND: Cancel the customer''s appointment. Customer name: Anmol Das.
            Customer phone: 9348611825. Appointment date: 2026-08-12. Appointment
            time: 15:00.


            If one of those cancellation requirements is genuinely missing from the
            conversation, DO NOT call the backend with an incomplete request. Use
            DIRECT: to ask the customer for the missing detail(s).


            RESCHEDULING REQUIREMENT:

            A reschedule request MUST contain:

            - customer name OR customer phone OR customer email

            - current appointment date

            - current appointment time

            - new appointment date and/or new appointment time


            If the customer says "move it to 4 PM", preserve the existing appointment
            date/time and customer identity from memory, and add the new time.

            Example:

            BACKEND: Reschedule the customer''s appointment. Customer phone: 9348611825.
            Current appointment date: 2026-08-12. Current appointment time: 15:00.
            New appointment date: 2026-08-12. New appointment time: 16:00.


            BOOKING CONTINUITY:

            When booking information arrives across turns, preserve it all.

            Example:

            Customer: "I want a facial tomorrow."

            Customer: "2 PM."

            Backend request must contain the service, normalized date, and time, not
            just "2 PM".


            If the customer says:

            - "actually 3 PM"

            - "make that Friday"

            - "same service"

            - "yes"

            you must use conversation context to understand what they mean.


            BACKEND MODE

            Use BACKEND: for anything requiring business data or business action,
            including:

            - services and service details

            - prices

            - appointment availability

            - booking

            - cancellation

            - rescheduling

            - appointment lookup

            - business-specific policies/FAQs


            For BACKEND mode, output ONE concise, complete, self-contained request.
            Include normalized date/time when applicable.


            Examples:

            BACKEND: What services do you offer?

            BACKEND: Please check whether a Facial appointment is available on 2026-08-12
            at 15:00.

            BACKEND: The customer wants to book a Facial on 2026-08-12 at 15:00. Customer
            name: Anmol Das. Customer phone: 9348611825. Please complete the booking
            flow and ask for any missing required details.

            BACKEND: Cancel the customer''s appointment. Customer name: Anmol Das.
            Customer phone: 9348611825. Appointment date: 2026-08-12. Appointment
            time: 15:00.

            BACKEND: Reschedule the customer''s appointment. Customer phone: 9348611825.
            Current appointment date: 2026-08-12. Current appointment time: 15:00.
            New appointment date: 2026-08-15. New appointment time: 17:00.


            DIRECT MODE

            Use DIRECT: only for greetings, thanks, goodbyes, casual conversation,
            or general non-business conversation that does not require business data.


            Direct replies should be warm and natural, but concise enough for a receptionist.


            IMPORTANT:

            - Never output JSON.

            - Never output markdown.

            - Never output <think>.

            - Never output analysis/reasoning.

            - Never put anything before DIRECT: or BACKEND:.

            - Never invent prices, services, policies, availability, booking IDs,
            or customer details.

            - Never tell the customer that a booking was completed unless the backend
            has actually confirmed it.

            - For business questions, prefer BACKEND over guessing.

            - If uncertain whether something requires business data, use BACKEND.


            FINAL SAFETY CHECK BEFORE OUTPUT:

            For CANCEL or RESCHEDULE, inspect the conversation one last time. If identity/date/time
            details are available, include them explicitly in the BACKEND line. Never
            discard previously collected appointment details merely because the newest
            user message is short.

            '
        - id: template-business-image-transfer
          role: system
          text: 'Business variables: clinic_name={{#env.clinic_name#}}, owner_name={{#env.owner_name#}}, business_hours={{#env.business_hours#}}, address={{#env.address#}}, phone={{#env.phone#}}, email={{#env.email#}}, services={{#env.services#}}, faq={{#env.faq#}}. Use these variables instead of hardcoded business facts. If the user asks for a receptionist, human, operator, or to be connected, do not call the backend; output exactly DIRECT: I''ll connect you with the clinic receptionist. Please wait a moment. If {{#start.image#}} exists, inspect it together with the user text for relevant clinic or medical information. Ask for a clearer image if it is unreadable; otherwise continue the normal receptionist workflow.'
        selected: false
        title: Receptionist Brain
        type: llm
        vision:
          enabled: true
      height: 87
      id: receptionist_llm
      position:
        x: 684
        y: 186.14285714285714
      positionAbsolute:
        x: 684
        y: 186.14285714285714
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        code: "\nimport json\nimport re\nfrom datetime import datetime, timedelta\n\
          \ntry:\n    from zoneinfo import ZoneInfo\nexcept Exception:\n    ZoneInfo\
          \ = None\n\nMONTHS = {\n    \"january\":1,\"february\":2,\"march\":3,\"\
          april\":4,\"may\":5,\"june\":6,\n    \"july\":7,\"august\":8,\"september\"\
          :9,\"october\":10,\"november\":11,\"december\":12\n}\nWEEKDAYS = {\n   \
          \ \"monday\":0,\"tuesday\":1,\"wednesday\":2,\"thursday\":3,\n    \"friday\"\
          :4,\"saturday\":5,\"sunday\":6\n}\n\ndef _parse_clock(value: str):\n   \
          \ s = value.strip().lower().replace(\".\", \"\")\n    m = re.fullmatch(r\"\
          (\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)?\", s)\n    if not m:\n        return\
          \ None\n    h = int(m.group(1))\n    minute = int(m.group(2) or \"0\")\n\
          \    ap = m.group(3)\n    if minute > 59:\n        return None\n    if ap:\n\
          \        if h < 1 or h > 12:\n            return None\n        if ap ==\
          \ \"am\":\n            h = 0 if h == 12 else h\n        else:\n        \
          \    h = 12 if h == 12 else h + 12\n    elif h > 23:\n        return None\n\
          \    return h, minute\n\ndef _fmt(dt):\n    return dt.strftime(\"%Y-%m-%d\"\
          )\n\ndef _normalize_relative_date(text, now):\n    low = text.lower()\n\n\
          \    if re.search(r\"\\bday after tomorrow\\b\", low):\n        return _fmt(now\
          \ + timedelta(days=2))\n    if re.search(r\"\\btomorrow\\b\", low):\n  \
          \      return _fmt(now + timedelta(days=1))\n    if re.search(r\"\\btoday\\\
          b\", low):\n        return _fmt(now)\n    if re.search(r\"\\byesterday\\\
          b\", low):\n        return _fmt(now - timedelta(days=1))\n\n    m = re.search(r\"\
          \\bin\\s+(\\d+)\\s+days?\\b\", low)\n    if m:\n        return _fmt(now\
          \ + timedelta(days=int(m.group(1))))\n\n    # \"next Monday\" / \"this Monday\"\
          \ / bare weekday.\n    m = re.search(\n        r\"\\b(next|this)?\\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\\
          b\",\n        low\n    )\n    if m:\n        target = WEEKDAYS[m.group(2)]\n\
          \        delta = (target - now.weekday()) % 7\n        if m.group(1) ==\
          \ \"next\" and delta == 0:\n            delta = 7\n        elif m.group(1)\
          \ == \"next\":\n            # \"next Tuesday\" means the next occurrence\
          \ after today.\n            delta = delta or 7\n        elif m.group(1)\
          \ == \"this\" and delta == 0:\n            delta = 0\n        return _fmt(now\
          \ + timedelta(days=delta))\n\n    # Explicit month/day, with optional year.\n\
          \    month_pattern = (\n        r\"\\b(january|february|march|april|may|june|july|august|\"\
          \n        r\"september|october|november|december)\\s+(\\d{1,2})(?:st|nd|rd|th)?\"\
          \n        r\"(?:,?\\s+(\\d{4}))?\\b\"\n    )\n    m = re.search(month_pattern,\
          \ low)\n    if not m:\n        m = re.search(\n            r\"\\b(\\d{1,2})(?:st|nd|rd|th)?\\\
          s+\"\n            r\"(january|february|march|april|may|june|july|august|\"\
          \n            r\"september|october|november|december)\"\n            r\"\
          (?:,?\\s+(\\d{4}))?\\b\",\n            low\n        )\n        if m:\n \
          \           day = int(m.group(1))\n            month = MONTHS[m.group(2)]\n\
          \            year = int(m.group(3) or now.year)\n        else:\n       \
          \     return \"\"\n    else:\n        month = MONTHS[m.group(1)]\n     \
          \   day = int(m.group(2))\n        year = int(m.group(3) or now.year)\n\n\
          \    try:\n        candidate = datetime(year, month, day)\n    except Exception:\n\
          \        return \"\"\n    if not m.group(3) and candidate.date() < now.date():\n\
          \        candidate = candidate.replace(year=year + 1)\n    return _fmt(candidate)\n\
          \ndef _normalize_relative_time(text, now):\n    low = text.lower()\n\n \
          \   # \"in 2 hours\", \"2 hours later\", \"in 30 minutes\", \"30 minutes\
          \ later\"\n    m = re.search(r\"\\b(?:in\\s+)?(\\d+)\\s*(hours?|hrs?|minutes?|mins?)\\\
          s+(?:later|from now)\\b\", low)\n    if not m:\n        m = re.search(r\"\
          \\bin\\s+(\\d+)\\s*(hours?|hrs?|minutes?|mins?)\\b\", low)\n    if m:\n\
          \        amount = int(m.group(1))\n        unit = m.group(2)\n        delta\
          \ = timedelta(hours=amount) if unit.startswith((\"hour\",\"hr\")) else timedelta(minutes=amount)\n\
          \        return (now + delta).strftime(\"%H:%M\")\n\n    # Common appointment\
          \ time forms.\n    time_patterns = [\n        r\"\\b(\\d{1,2}(?::\\d{2})?\\\
          s*(?:am|pm))\\b\",\n        r\"\\b(\\d{1,2}:\\d{2})\\b\",\n        r\"\\\
          bat\\s+(\\d{1,2})\\b\",\n    ]\n    for pat in time_patterns:\n        m\
          \ = re.search(pat, low)\n        if m:\n            parsed = _parse_clock(m.group(1))\n\
          \            if parsed:\n                return f\"{parsed[0]:02d}:{parsed[1]:02d}\"\
          \n    return \"\"\n\ndef main(llm_text: str = \"\", timezone: str = \"Asia/Kolkata\"\
          , current_datetime: str = \"\") -> dict:\n    text = str(llm_text or \"\"\
          ).strip()\n\n    # Remove model reasoning and common fences.\n    text =\
          \ re.sub(r\"<think>.*?</think>\", \"\", text, flags=re.IGNORECASE | re.DOTALL).strip()\n\
          \    text = re.sub(r\"<analysis>.*?</analysis>\", \"\", text, flags=re.IGNORECASE\
          \ | re.DOTALL).strip()\n    text = re.sub(r\"```(?:text|markdown)?\", \"\
          \", text, flags=re.IGNORECASE).replace(\"```\", \"\").strip()\n\n    # Parse\
          \ the explicit route marker even if the model put it on a later line.\n\
          \    match = re.search(r\"(?im)^\\s*(BACKEND|DIRECT)\\s*:\\s*(.*)$\", text)\n\
          \    if match:\n        route = match.group(1).lower()\n        message\
          \ = match.group(2).strip()\n    else:\n        route = \"backend\"\n   \
          \     message = text.strip()\n\n    if not message:\n        message = \"\
          Please help me with my appointment.\" if route == \"backend\" else \"How\
          \ can I help you today?\"\n\n    # Deterministic safety-net normalization.\
          \ The LLM is still the primary\n    # conversational interpreter; these\
          \ additions only make relative dates/times\n    # explicit for the backend\
          \ when the original phrase is present.\n    try:\n        if ZoneInfo is\
          \ not None:\n            tz = ZoneInfo(str(timezone or \"Asia/Kolkata\"\
          ))\n        else:\n            tz = None\n        now = datetime.now(tz)\
          \ if tz else datetime.now()\n    except Exception:\n        now = datetime.now()\n\
          \n    if route == \"backend\":\n        date_value = _normalize_relative_date(message,\
          \ now)\n        time_value = _normalize_relative_time(message, now)\n  \
          \      additions = []\n        if date_value and not re.search(r\"\\b\\\
          d{4}-\\d{2}-\\d{2}\\b\", message):\n            additions.append(f\"Normalized\
          \ date: {date_value}.\")\n        if time_value and not re.search(r\"\\\
          b\\d{1,2}:\\d{2}\\b\", message):\n            additions.append(f\"Normalized\
          \ time: {time_value}.\")\n        if additions:\n            message = message.rstrip()\
          \ + \" \" + \" \".join(additions)\n\n    # Deterministic safety guard for\
          \ cancellation/rescheduling.\n    # The backend explicitly requires customer\
          \ identity + appointment date/time.\n    low = message.lower()\n    is_cancel\
          \ = bool(re.search(r\"\\b(cancel|cancellation|call off)\\b\", low))\n  \
          \  is_reschedule = bool(re.search(r\"\\b(reschedule|rescheduling|move|change)\\\
          b\", low))\n\n    if route == \"backend\" and (is_cancel or is_reschedule):\n\
          \        has_identity = bool(\n            re.search(r\"\\bcustomer\\s+(?:name|phone|email)\\\
          s*:\", low)\n            or re.search(r\"\\b(?:name|phone|email)\\s*:\"\
          , low)\n            or re.search(r\"\\b(?:phone|mobile|email)\\b.*\\d{7,}\"\
          , low)\n        )\n        dates = re.findall(r\"\\b\\d{4}-\\d{2}-\\d{2}\\\
          b\", message)\n        times = re.findall(r\"\\b\\d{1,2}:\\d{2}\\b\", message)\n\
          \n        if not has_identity or not dates or not times:\n            missing\
          \ = []\n            if not has_identity:\n                missing.append(\"\
          your name, phone number, or email\")\n            if not dates:\n      \
          \          missing.append(\"the appointment date\")\n            if not\
          \ times:\n                missing.append(\"the appointment time\")\n\n \
          \           if is_reschedule:\n                prefix = \"Before I reschedule\
          \ it, \"\n            else:\n                prefix = \"Before I cancel\
          \ it, \"\n\n            if len(missing) == 1:\n                ask = missing[0]\n\
          \            elif len(missing) == 2:\n                ask = f\"{missing[0]}\
          \ and {missing[1]}\"\n            else:\n                ask = \", \".join(missing[:-1])\
          \ + f\", and {missing[-1]}\"\n\n            route = \"direct\"\n       \
          \     message = prefix + f\"I need {ask}. Please provide the missing detail(s).\"\
          \n\n    return {\n        \"route\": route,\n        \"message\": message,\n\
          \        \"message_json\": json.dumps(message, ensure_ascii=False)\n   \
          \ }\n"
        code_language: python3
        desc: Parses the LLM route, removes reasoning, normalizes relative dates/times,
          and blocks incomplete cancellation/rescheduling requests.
        outputs:
          message:
            children: null
            type: string
          message_json:
            children: null
            type: string
          route:
            children: null
            type: string
        selected: false
        title: Parse & Normalize Request
        type: code
        variables:
        - value_selector:
          - receptionist_llm
          - text
          variable: llm_text
        - value_selector:
          - business_clock
          - timezone
          variable: timezone
        - value_selector:
          - business_clock
          - current_datetime
          variable: current_datetime
      height: 127
      id: route_request
      position:
        x: 1026
        y: 180.64285714285714
      positionAbsolute:
        x: 1026
        y: 180.64285714285714
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        cases:
        - case_id: backend
          conditions:
          - comparison_operator: is
            id: condition_backend
            value: backend
            varType: string
            variable_selector:
            - route_request
            - route
          desc: Route only when the LLM explicitly selected BACKEND.
          logical_operator: and
        desc: Sends only BACKEND requests to the authenticated business backend.
        selected: false
        title: Call Backend?
        type: if-else
      height: 167
      id: route
      position:
        x: 1368
        y: 181.80952380952377
      positionAbsolute:
        x: 1368
        y: 181.80952380952377
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        answer: '{{#route_request.message#}}'
        selected: false
        title: Direct Answer
        type: answer
        variables: []
      height: 101
      id: direct_answer
      position:
        x: 1730
        y: 375.5238095238095
      positionAbsolute:
        x: 1730
        y: 375.5238095238095
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        authorization:
          config:
            api_key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4MzQ1NjdjYS02YjU2LTQxYTMtYTEzMy04NzliM2I1YTY5YTgiLCJjbGllbnRJZCI6ImJkNWYyZDQ5LTY0NjAtNGMwMS05MzU1LTE5YTBhMTk4YWI5NiIsInJvbGUiOiJPd25lciIsImlhdCI6MTc4NjIwOTQ0NSwiZXhwIjoxNzg2ODE0MjQ1fQ.aObvAKkeeIXRjLHNj6IJUgZ-gm3t2LxpvBAEAbtgy3M
            type: bearer
          type: api-key
        body:
          data:
          - id: json-body
            key: ''
            type: text
            value: '{"message": {{#route_request.message_json#}}}'
          type: json
        desc: Calls the supplied authenticated /api/ai/chat backend. Retries are disabled
          to reduce duplicate booking risk.
        error_strategy: fail-branch
        headers: 'Content-Type:application/json

          Authorization:Bearer {{#env.JWT_BEARER#}}'
        method: post
        params: ''
        retry_config:
          max_retries: 0
          retry_enabled: false
          retry_interval: 100
        selected: false
        ssl_verify: true
        timeout:
          max_connect_timeout: 10
          max_read_timeout: 60
          max_write_timeout: 10
        title: AI Receptionist Backend
        type: http-request
        url: '{{#env.BACKEND_BASE_URL#}}/api/ai/chat'
        variables: []
      height: 219
      id: backend_request
      position:
        x: 1730
        y: 76.52380952380949
      positionAbsolute:
        x: 1730
        y: 76.52380952380949
      selected: true
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        code: "\nimport json\n\ndef _json_load(value):\n    if isinstance(value, (dict,\
          \ list)):\n        return value\n    if not isinstance(value, str):\n  \
          \      return value\n    text = value.strip()\n    if not text:\n      \
          \  return None\n    # Some HTTP responses can be JSON encoded more than\
          \ once.\n    for _ in range(3):\n        try:\n            parsed = json.loads(text)\n\
          \        except Exception:\n            return value\n        if isinstance(parsed,\
          \ str):\n            text = parsed.strip()\n            continue\n     \
          \   return parsed\n    return value\n\ndef _find_message(obj):\n    \"\"\
          \"Recursively find the backend's own customer-facing message.\"\"\"\n  \
          \  if isinstance(obj, dict):\n        # Prefer message-like fields at the\
          \ current level.\n        for key in (\"message\", \"reply\", \"response\"\
          , \"text\"):\n            value = obj.get(key)\n            if isinstance(value,\
          \ str) and value.strip():\n                return value.strip()\n\n    \
          \    # Then inspect the normal controller nesting.\n        for key in (\"\
          data\", \"result\", \"response\", \"body\"):\n            if key in obj:\n\
          \                found = _find_message(obj[key])\n                if found:\n\
          \                    return found\n\n        # Finally inspect any remaining\
          \ nested values.\n        for value in obj.values():\n            found\
          \ = _find_message(value)\n            if found:\n                return\
          \ found\n\n    elif isinstance(obj, list):\n        for value in obj:\n\
          \            found = _find_message(value)\n            if found:\n     \
          \           return found\n\n    return \"\"\n\ndef _find_services(obj):\n\
          \    if isinstance(obj, dict):\n        services = obj.get(\"services\"\
          )\n        if isinstance(services, list):\n            return services\n\
          \        for value in obj.values():\n            found = _find_services(value)\n\
          \            if found:\n                return found\n    elif isinstance(obj,\
          \ list):\n        for value in obj:\n            found = _find_services(value)\n\
          \            if found:\n                return found\n    return []\n\n\
          def _format_services(services):\n    lines = []\n    for service in services:\n\
          \        if not isinstance(service, dict):\n            continue\n\n   \
          \     name = service.get(\"name\") or service.get(\"service_name\")\n  \
          \      if not name:\n            continue\n\n        duration = (\n    \
          \        service.get(\"duration_minutes\")\n            or service.get(\"\
          duration\")\n        )\n        price = service.get(\"price\")\n       \
          \ currency = service.get(\"currency\") or \"INR\"\n        description =\
          \ service.get(\"description\")\n\n        parts = [f\"• {name}\"]\n    \
          \    if duration not in (None, \"\"):\n            parts.append(f\"{duration}\
          \ min\")\n        if price not in (None, \"\"):\n            parts.append(f\"\
          {price} {currency}\")\n        if description:\n            parts.append(str(description).strip())\n\
          \n        lines.append(\"\\n\".join(parts))\n\n    if lines:\n        return\
          \ \"Available services:\\n\\n\" + \"\\n\\n\".join(lines)\n    return \"\"\
          \n\ndef _format_booking(obj):\n    # Search for a booking object in common\
          \ backend shapes.\n    candidates = []\n    if isinstance(obj, dict):\n\
          \        candidates.extend([\n            obj.get(\"booking\"),\n      \
          \      obj.get(\"data\"),\n            obj.get(\"result\"),\n        ])\n\
          \n    for item in candidates:\n        if not isinstance(item, dict):\n\
          \            continue\n        if any(item.get(k) for k in (\n         \
          \   \"appointment_date\", \"appointment_time\", \"customer_name\",\n   \
          \         \"service_name\", \"service\"\n        )):\n            lines\
          \ = [\"Your appointment has been booked successfully.\"]\n            for\
          \ label, keys in [\n                (\"Name\", (\"customer_name\",)),\n\
          \                (\"Service\", (\"service_name\", \"service\")),\n     \
          \           (\"Date\", (\"appointment_date\", \"date\")),\n            \
          \    (\"Time\", (\"appointment_time\", \"time\")),\n            ]:\n   \
          \             value = next((item.get(k) for k in keys if item.get(k)), None)\n\
          \                if value:\n                    lines.append(f\"{label}:\
          \ {value}\")\n            return \"\\n\".join(lines)\n    return \"\"\n\n\
          def _format_availability(obj):\n    # Preserve the backend's message first;\
          \ this is only a fallback.\n    if not isinstance(obj, dict):\n        return\
          \ \"\"\n\n    available = obj.get(\"available\")\n    if available is None:\n\
          \        nested = obj.get(\"data\")\n        if isinstance(nested, dict):\n\
          \            available = nested.get(\"available\")\n\n    if available is\
          \ True:\n        return \"That appointment time is available.\"\n    if\
          \ available is False:\n        return \"That appointment time is not available.\
          \ Please choose another time.\"\n    return \"\"\n\ndef main(body=None)\
          \ -> dict:\n    data = _json_load(body)\n\n    if data is None or data ==\
          \ \"\":\n        return {\n            \"message\": \"I'm sorry, I didn't\
          \ receive a response from the appointment system.\"\n        }\n\n    #\
          \ If Dify hands us an object whose body is itself JSON, unwrap it.\n   \
          \ if isinstance(data, dict) and isinstance(data.get(\"body\"), (str, dict,\
          \ list)):\n        inner = _json_load(data.get(\"body\"))\n        if inner\
          \ is not None:\n            data = inner\n\n    if not isinstance(data,\
          \ (dict, list)):\n        return {\"message\": str(data)}\n    # Determine\
          \ the backend operation before formatting any appointment data.\nintent\
          \ = \"\"\n\nif isinstance(data, dict):\n    intent = str(data.get(\"intent\"\
          ) or \"\").strip().lower()\n\n    if not intent:\n        nested = data.get(\"\
          data\")\n        if isinstance(nested, dict):\n            intent = str(nested.get(\"\
          intent\") or \"\").strip().lower()\n\n# Cancellation MUST be handled before\
          \ the booking formatter.\nif intent in (\"cancel\", \"cancellation\", \"\
          cancel_appointment\"):\n    return {\n        \"message\": \"Your appointment\
          \ has been cancelled successfully.\"\n    }\n\n# Rescheduling MUST also\
          \ be handled before the booking formatter.\nif intent in (\"reschedule\"\
          , \"rescheduling\", \"reschedule_appointment\"):\n    return {\n       \
          \ \"message\": \"Your appointment has been rescheduled successfully.\"\n\
          \    }   \n    # 1. ALWAYS prefer the backend's own customer-facing message.\n\
          \    message = _find_message(data)\n    if message:\n        return {\"\
          message\": message}\n\n    # 2. Services fallback.\n    services = _find_services(data)\n\
          \    if services:\n        formatted = _format_services(services)\n    \
          \    if formatted:\n            return {\"message\": formatted}\n\n    #\
          \ 3. Booking fallback.\n    booking = _format_booking(data)\n    if booking:\n\
          \        return {\"message\": booking}\n\n    # 4. Availability fallback.\n\
          \    availability = _format_availability(data)\n    if availability:\n \
          \       return {\"message\": availability}\n\n    # 5. Explicit backend\
          \ errors.\n    if isinstance(data, dict):\n        error = data.get(\"error_message\"\
          ) or data.get(\"error\")\n        if isinstance(error, str) and error.strip():\n\
          \            return {\"message\": error.strip()}\n\n    return {\n     \
          \   \"message\": (\n            \"I'm sorry, the appointment system completed\
          \ the request but \"\n            \"did not return a customer-facing message.\
          \ Please try again.\"\n        )\n    }\n"
        code_language: python3
        desc: Extracts the backend's customer-facing message and safely formats service,
          availability, booking, cancellation, and rescheduling results. No second
          LLM.
        outputs:
          message:
            children: null
            type: string
        selected: false
        title: Backend Response
        type: code
        variables:
        - value_selector:
          - backend_request
          - body
          variable: body
      height: 127
      id: backend_response
      position:
        x: 2092
        y: 0
      positionAbsolute:
        x: 2092
        y: 0
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        code: |
          import json
          def unpack(v):
              if isinstance(v, str):
                  try: return json.loads(v)
                  except Exception: return {}
              return v if isinstance(v, dict) else {}
          def find(d, keys):
              if isinstance(d, dict):
                  for k in keys:
                      if d.get(k) not in (None, ''): return str(d[k])
                  for v in d.values():
                      x = find(v, keys)
                      if x: return x
              if isinstance(d, list):
                  for v in d:
                      x = find(v, keys)
                      if x: return x
              return ''
          def main(body=None):
              d = unpack(body)
              if isinstance(d.get('body'), str): d = unpack(d['body'])
              operation = find(d, ('intent','operation','action')).lower()
              booking_id = find(d, ('booking_id','appointment_id','id','reference_id'))
              date = find(d, ('new_appointment_date','new_date','appointment_date','date'))
              time = find(d, ('new_appointment_time','new_time','appointment_time','time'))
              doctor = find(d, ('doctor','doctor_name','provider_name'))
              if 'cancel' in operation:
                  return {'operation':'cancel','message':'Your appointment has been cancelled successfully.' + ('\nBooking ID: ' + booking_id if booking_id else '')}
              if 'resched' in operation:
                  parts=['Your appointment has been rescheduled successfully.']
                  if date: parts.append('New Date: ' + date)
                  if time: parts.append('New Time: ' + time)
                  if booking_id: parts.append('Booking ID: ' + booking_id)
                  return {'operation':'reschedule','message':'\n'.join(parts)}
              if any(x in operation for x in ('book','create','appointment')):
                  parts=['Your appointment has been booked successfully.']
                  if doctor: parts.append('Doctor: ' + doctor)
                  if date: parts.append('Date: ' + date)
                  if time: parts.append('Time: ' + time)
                  if booking_id: parts.append('Booking ID: ' + booking_id)
                  return {'operation':'book','message':'\n'.join(parts)}
              return {'operation':'other','message':find(d, ('message','reply','response','text')) or 'I could not complete your appointment right now. Please try again in a few moments.'}
        code_language: python3
        desc: Formats each confirmed appointment operation independently.
        outputs:
          operation:
            children: null
            type: string
          message:
            children: null
            type: string
        selected: false
        title: Format Appointment Response
        type: code
        variables:
        - value_selector: [backend_request, body]
          variable: body
      height: 154
      id: response_format
      position:
        x: 2092
        y: 0
      positionAbsolute:
        x: 2092
        y: 0
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        cases:
        - case_id: book
          conditions:
          - comparison_operator: is
            id: response-is-book
            value: book
            varType: string
            variable_selector: [response_format, operation]
          logical_operator: and
        - case_id: cancel
          conditions:
          - comparison_operator: is
            id: response-is-cancel
            value: cancel
            varType: string
            variable_selector: [response_format, operation]
          logical_operator: and
        - case_id: reschedule
          conditions:
          - comparison_operator: is
            id: response-is-reschedule
            value: reschedule
            varType: string
            variable_selector: [response_format, operation]
          logical_operator: and
        desc: Routes confirmed booking, cancellation, and rescheduling to independent response nodes.
        selected: false
        title: Appointment Success Router
        type: if-else
      height: 220
      id: response_route
      position:
        x: 2434
        y: 0
      positionAbsolute:
        x: 2434
        y: 0
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        answer: '{{#response_format.message#}}'
        selected: false
        title: Book Success
        type: answer
        variables: []
      height: 101
      id: final_answer
      position:
        x: 2434
        y: 34.16666666666664
      positionAbsolute:
        x: 2434
        y: 34.16666666666664
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        code: "\ndef main(error: str = \"\") -> dict:\n    text=str(error or \"\"\
          ).lower()\n    if \"401\" in text or \"403\" in text or \"unauthorized\"\
          \ in text or \"forbidden\" in text:\n        return {\"message\":\"I'm sorry,\
          \ the appointment system is not authorized right now. Please try again in\
          \ a moment.\"}\n    if \"timeout\" in text or \"timed out\" in text:\n \
          \       return {\"message\":\"I'm sorry, the appointment system took too\
          \ long to respond. Please try again.\"}\n    if \"429\" in text or \"rate\
          \ limit\" in text:\n        return {\"message\":\"The appointment system\
          \ is temporarily busy. Please try again in a moment.\"}\n    return {\"\
          message\":\"I'm sorry, I couldn't complete that request right now. Please\
          \ try again.\"}\n"
        code_language: python3
        desc: Converts an HTTP/backend failure into a safe customer-facing message.
        outputs:
          message:
            children: null
            type: string
        selected: false
        title: Backend Failure
        type: code
        variables:
        - value_selector:
          - backend_request
          - error_message
          variable: error
      height: 95
      id: backend_failure
      position:
        x: 2092
        y: 224.3333333333333
      positionAbsolute:
        x: 2092
        y: 224.3333333333333
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        answer: I couldn't complete your appointment right now. Please try again in a few moments.
        desc: Displays the safe backend failure response.
        selected: false
        title: Backend Error Response
        type: answer
        variables: []
      height: 145
      id: failure_answer
      position:
        x: 2434
        y: 215.16666666666663
      positionAbsolute:
        x: 2434
        y: 215.16666666666663
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        answer: '{{#response_format.message#}}'
        selected: false
        title: Cancel Success
        type: answer
        variables: []
      height: 101
      id: cancel_success
      position: {x: 2776, y: 120}
      positionAbsolute: {x: 2776, y: 120}
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    - data:
        answer: '{{#response_format.message#}}'
        selected: false
        title: Reschedule Success
        type: answer
        variables: []
      height: 101
      id: reschedule_success
      position: {x: 2776, y: 260}
      positionAbsolute: {x: 2776, y: 260}
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 242
      zIndex: 0
    viewport:
      x: 117.51668352726699
      y: 190.3908538967345
      zoom: 0.39174859347467034
  rag_pipeline_variables: []
