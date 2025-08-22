export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.3 (519615d)"
  }
  public: {
    Tables: {
      budget_alerts: {
        Row: {
          budget_id: string
          created_at: string | null
          id: string
          is_notified: boolean | null
          notified_at: string | null
          threshold_percentage: number
        }
        Insert: {
          budget_id: string
          created_at?: string | null
          id?: string
          is_notified?: boolean | null
          notified_at?: string | null
          threshold_percentage: number
        }
        Update: {
          budget_id?: string
          created_at?: string | null
          id?: string
          is_notified?: boolean | null
          notified_at?: string | null
          threshold_percentage?: number
        }
        Relationships: [
          {
            foreignKeyName: "budget_alerts_budget_id_fkey"
            columns: ["budget_id"]
            isOneToOne: false
            referencedRelation: "budget_summary"
            referencedColumns: ["budget_id"]
          },
          {
            foreignKeyName: "budget_alerts_budget_id_fkey"
            columns: ["budget_id"]
            isOneToOne: false
            referencedRelation: "budgets"
            referencedColumns: ["id"]
          },
        ]
      }
      budgets: {
        Row: {
          amount: number
          category_id: string | null
          created_at: string | null
          end_date: string | null
          family_group_id: string | null
          id: string
          is_active: boolean | null
          name: string
          period_type: string
          start_date: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          amount: number
          category_id?: string | null
          created_at?: string | null
          end_date?: string | null
          family_group_id?: string | null
          id?: string
          is_active?: boolean | null
          name: string
          period_type: string
          start_date: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          amount?: number
          category_id?: string | null
          created_at?: string | null
          end_date?: string | null
          family_group_id?: string | null
          id?: string
          is_active?: boolean | null
          name?: string
          period_type?: string
          start_date?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          color: string | null
          created_at: string | null
          family_group_id: string | null
          icon: string | null
          id: string
          is_system: boolean | null
          name: string
          parent_id: string | null
          sort_order: number | null
          type: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          color?: string | null
          created_at?: string | null
          family_group_id?: string | null
          icon?: string | null
          id?: string
          is_system?: boolean | null
          name: string
          parent_id?: string | null
          sort_order?: number | null
          type: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          color?: string | null
          created_at?: string | null
          family_group_id?: string | null
          icon?: string | null
          id?: string
          is_system?: boolean | null
          name?: string
          parent_id?: string | null
          sort_order?: number | null
          type?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "categories_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "categories_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      family_groups: {
        Row: {
          created_at: string | null
          created_by: string
          description: string | null
          id: string
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          created_by: string
          description?: string | null
          id?: string
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          created_by?: string
          description?: string | null
          id?: string
          name?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "family_groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      family_members: {
        Row: {
          group_id: string
          id: string
          joined_at: string | null
          role: string
          user_id: string
        }
        Insert: {
          group_id: string
          id?: string
          joined_at?: string | null
          role: string
          user_id: string
        }
        Update: {
          group_id?: string
          id?: string
          joined_at?: string | null
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "family_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "family_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      installments: {
        Row: {
          category_id: string
          created_at: string | null
          description: string | null
          end_date: string
          id: string
          installment_months: number
          merchant: string | null
          monthly_amount: number
          original_transaction_id: string | null
          payment_day: number
          payment_method: string | null
          start_date: string
          total_amount: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          category_id: string
          created_at?: string | null
          description?: string | null
          end_date: string
          id?: string
          installment_months: number
          merchant?: string | null
          monthly_amount: number
          original_transaction_id?: string | null
          payment_day: number
          payment_method?: string | null
          start_date: string
          total_amount: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          category_id?: string
          created_at?: string | null
          description?: string | null
          end_date?: string
          id?: string
          installment_months?: number
          merchant?: string | null
          monthly_amount?: number
          original_transaction_id?: string | null
          payment_day?: number
          payment_method?: string | null
          start_date?: string
          total_amount?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "installments_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "installments_original_transaction_id_fkey"
            columns: ["original_transaction_id"]
            isOneToOne: false
            referencedRelation: "transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "installments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          currency: string | null
          full_name: string | null
          id: string
          locale: string | null
          updated_at: string | null
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          currency?: string | null
          full_name?: string | null
          id: string
          locale?: string | null
          updated_at?: string | null
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          currency?: string | null
          full_name?: string | null
          id?: string
          locale?: string | null
          updated_at?: string | null
          username?: string | null
        }
        Relationships: []
      }
      receipts: {
        Row: {
          created_at: string | null
          id: string
          image_url: string
          merchant_name: string | null
          ocr_result: Json | null
          ocr_status: string | null
          receipt_date: string | null
          thumbnail_url: string | null
          total_amount: number | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          image_url: string
          merchant_name?: string | null
          ocr_result?: Json | null
          ocr_status?: string | null
          receipt_date?: string | null
          thumbnail_url?: string | null
          total_amount?: number | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          image_url?: string
          merchant_name?: string | null
          ocr_result?: Json | null
          ocr_status?: string | null
          receipt_date?: string | null
          thumbnail_url?: string | null
          total_amount?: number | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "receipts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      recurring_transactions: {
        Row: {
          amount: number
          category_id: string
          created_at: string | null
          day_of_month: number | null
          day_of_week: number | null
          description: string | null
          end_date: string | null
          family_group_id: string | null
          frequency: string
          id: string
          interval_value: number | null
          is_active: boolean | null
          merchant: string | null
          next_date: string
          payment_method: string | null
          start_date: string
          type: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          amount: number
          category_id: string
          created_at?: string | null
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_date?: string | null
          family_group_id?: string | null
          frequency: string
          id?: string
          interval_value?: number | null
          is_active?: boolean | null
          merchant?: string | null
          next_date: string
          payment_method?: string | null
          start_date: string
          type: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          category_id?: string
          created_at?: string | null
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_date?: string | null
          family_group_id?: string | null
          frequency?: string
          id?: string
          interval_value?: number | null
          is_active?: boolean | null
          merchant?: string | null
          next_date?: string
          payment_method?: string | null
          start_date?: string
          type?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recurring_transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recurring_transactions_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recurring_transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      transactions: {
        Row: {
          amount: number
          category_id: string
          created_at: string | null
          description: string | null
          family_group_id: string | null
          id: string
          installment_id: string | null
          installment_months: number | null
          is_recurring: boolean | null
          merchant: string | null
          payment_method: string | null
          receipt_id: string | null
          recurring_id: string | null
          tags: string[] | null
          transaction_date: string
          transaction_time: string | null
          type: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          amount: number
          category_id: string
          created_at?: string | null
          description?: string | null
          family_group_id?: string | null
          id?: string
          installment_id?: string | null
          installment_months?: number | null
          is_recurring?: boolean | null
          merchant?: string | null
          payment_method?: string | null
          receipt_id?: string | null
          recurring_id?: string | null
          tags?: string[] | null
          transaction_date: string
          transaction_time?: string | null
          type: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          category_id?: string
          created_at?: string | null
          description?: string | null
          family_group_id?: string | null
          id?: string
          installment_id?: string | null
          installment_months?: number | null
          is_recurring?: boolean | null
          merchant?: string | null
          payment_method?: string | null
          receipt_id?: string | null
          recurring_id?: string | null
          tags?: string[] | null
          transaction_date?: string
          transaction_time?: string | null
          type?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_installment_id_fkey"
            columns: ["installment_id"]
            isOneToOne: false
            referencedRelation: "installments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_receipt_id_fkey"
            columns: ["receipt_id"]
            isOneToOne: false
            referencedRelation: "receipts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_recurring_id_fkey"
            columns: ["recurring_id"]
            isOneToOne: false
            referencedRelation: "recurring_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      budget_summary: {
        Row: {
          budget_amount: number | null
          budget_id: string | null
          budget_name: string | null
          category_id: string | null
          category_name: string | null
          created_at: string | null
          family_group_id: string | null
          is_active: boolean | null
          period_type: string | null
          updated_at: string | null
          usage_percentage: number | null
          used_amount: number | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      category_summary: {
        Row: {
          category_id: string | null
          category_name: string | null
          category_type: string | null
          family_group_id: string | null
          month: string | null
          total_amount: number | null
          transaction_count: number | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      daily_summary: {
        Row: {
          family_group_id: string | null
          total_amount: number | null
          transaction_count: number | null
          transaction_date: string | null
          transaction_ids: string[] | null
          type: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      monthly_summary: {
        Row: {
          family_group_id: string | null
          month: string | null
          total_amount: number | null
          transaction_count: number | null
          type: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_family_group_id_fkey"
            columns: ["family_group_id"]
            isOneToOne: false
            referencedRelation: "family_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      calculate_budget_usage: {
        Args: { budget_id: string }
        Returns: {
          usage_percentage: number
          used_amount: number
        }[]
      }
      check_budget_alerts: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      cleanup_old_transactions: {
        Args: { months_to_keep?: number }
        Returns: number
      }
      create_installment_transactions: {
        Args: {
          p_category_id: string
          p_description: string
          p_installment_months: number
          p_merchant: string
          p_payment_method: string
          p_start_date: string
          p_total_amount: number
          p_user_id: string
        }
        Returns: string
      }
      delete_installment_transactions: {
        Args: { p_installment_id: string; p_user_id: string }
        Returns: boolean
      }
      get_installment_summary: {
        Args: { p_month?: string; p_user_id: string }
        Returns: {
          current_month: number
          installment_id: string
          merchant: string
          monthly_amount: number
          remaining_amount: number
          total_amount: number
          total_months: number
        }[]
      }
      get_system_categories: {
        Args: { p_type?: string }
        Returns: {
          color: string | null
          created_at: string | null
          family_group_id: string | null
          icon: string | null
          id: string
          is_system: boolean | null
          name: string
          parent_id: string | null
          sort_order: number | null
          type: string
          updated_at: string | null
          user_id: string | null
        }[]
      }
      get_transaction_stats: {
        Args: { p_end_date?: string; p_start_date?: string; p_user_id: string }
        Returns: {
          average_transaction: number
          net_amount: number
          top_expense_amount: number
          top_expense_category: string
          total_expense: number
          total_income: number
          transaction_count: number
        }[]
      }
      process_recurring_transactions: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      process_recurring_transactions_for_date: {
        Args: { p_date: string }
        Returns: number
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const