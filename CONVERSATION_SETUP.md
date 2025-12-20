# Quote AI - Conversation Storage Setup Guide

## ✅ What's Been Added

Your Quote AI app now has **automatic conversation history**! Here's what was implemented:

### 1. Database Models (`ConversationModels.swift`)
- **Conversation**: Stores conversation metadata (ID, user, title, timestamps)
- **StoredMessage**: Stores individual messages with conversation references

### 2. Enhanced SupabaseManager
Added functions to:
- ✅ Create new conversations
- ✅ Save messages automatically
- ✅ Fetch conversation history
- ✅ Load specific conversations
- ✅ Delete conversations

### 3. Auto-Save in ChatViewModel
- **First message** → Creates a new conversation
- **Every message** → Automatically saved to database
- **Load conversations** → Retrieve past chats

## 🎯 Setup Instructions

### Step 1: Create Database Tables in Supabase

1. Go to [supabase.com](https://supabase.com) and log in
2. Select your Quote AI project
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `supabase-schema.sql` (located in your project folder)
6. Paste it into the SQL Editor
7. Click **RUN** button

This will create:
- ✅ `conversations` table
- ✅ `messages` table
- ✅ Indexes for performance
- ✅ Row Level Security (RLS) policies
- ✅ Auto-update triggers

### Step 2: Verify Tables Created

1. In Supabase dashboard, go to **Table Editor**
2. You should see two new tables:
   - `conversations`
   - `messages`

### Step 3: Test the Feature

1. **Build and run** your app in Xcode
2. Sign in with Google or Apple
3. Send a message in the chat
4. Go to Supabase → **Table Editor** → **conversations**
5. You should see your conversation appear!
6. Click on **messages** table
7. You should see your messages saved there!

## 🎨 How It Works

```
User sends message
       ↓
1. Creates conversation (first message only)
2. Saves user message to database
3. Gets AI quote
4. Saves AI response to database
       ↓
All messages stored automatically!
```

## 📊 Database Schema

### Conversations Table
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Unique conversation ID |
| user_id | TEXT | User's ID from auth |
| title | TEXT | Auto-generated from first message |
| created_at | TIMESTAMP | When conversation started |
| updated_at | TIMESTAMP | Last message time |

### Messages Table
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Unique message ID |
| conversation_id | UUID | Links to conversation |
| content | TEXT | Message text |
| is_user | BOOLEAN | true for user, false for AI |
| timestamp | TIMESTAMP | When message was sent |

## 🔒 Security Features

**Row Level Security (RLS)** is enabled, which means:
- ✅ Users can ONLY see their own conversations
- ✅ Users can ONLY see their own messages
- ✅ No one can access other users' data
- ✅ Database enforces these rules automatically

## 🚀 Future Features You Can Add

Now that conversations are stored, you can easily add:

1. **Conversation History Screen**
   - Show list of past conversations
   - Click to load old chats
   
2. **Search**
   - Search through all past messages
   
3. **Delete Conversations**
   - Already have the function: `deleteConversation()`
   
4. **Edit Conversation Titles**
   - Change the auto-generated titles

5. **Export Conversations**
   - Download as PDF or text

## 📝 Example: Adding a History Screen

Want to show conversation history? Here's a quick example:

```swift
struct ConversationHistoryView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        List(conversations) { conversation in
            VStack(alignment: .leading) {
                Text(conversation.title)
                    .font(.headline)
                Text(conversation.updatedAt.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .task {
            do {
                conversations = try await supabase.fetchConversations()
            } catch {
                print("Error fetching conversations: \(error)")
            }
        }
    }
}
```

## 🐛 Troubleshooting

### Messages not saving?
1. Check Supabase dashboard → **Table Editor** → Make sure tables exist
2. Check **Authentication** → Make sure user is signed in
3. Check Xcode console for error messages

### "User not authenticated" error?
- Make sure you're signed in before sending messages
- Check `SupabaseManager.shared.currentUser` is not nil

### RLS policy errors?
- Make sure you ran the ENTIRE SQL schema
- Check **Authentication** → **Policies** tab in Supabase

## ✨ That's It!

Your app now automatically saves all conversations! Every message is backed up to your Supabase database, and you can easily build features to view, search, and manage conversation history.

Need help adding a conversation history screen? Just ask! 🚀
