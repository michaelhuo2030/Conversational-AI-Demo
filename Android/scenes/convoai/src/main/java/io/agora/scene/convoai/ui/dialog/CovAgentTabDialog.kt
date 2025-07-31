package io.agora.scene.convoai.ui.dialog

import android.animation.ValueAnimator
import android.animation.AnimatorListenerAdapter
import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.LinearInterpolator
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.google.android.material.tabs.TabLayout
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.convoai.R
import io.agora.scene.convoai.constant.AgentConnectionState
import io.agora.scene.convoai.databinding.CovAgentTabDialogBinding

/**
 * Bottom sheet dialog with tab switching functionality
 * Contains Channel Info and Agent Settings tabs
 */
class CovAgentTabDialog : BaseSheetDialog<CovAgentTabDialogBinding>() {

    private var onDismissCallback: (() -> Unit)? = null
    private var agentState: AgentConnectionState? = null
    private var initialTab: Int = TAB_AGENT_SETTINGS

    // Tab indicator animation variables
    private var tabIndicatorAnimator: ValueAnimator? = null
    private var tabWidth: Int = 0

    companion object {
        private const val TAG = "CovInfoTabDialog"

        // Tab indices
        const val TAB_AGENT_SETTINGS = 0
        const val TAB_CHANNEL_INFO = 1

        fun newInstance(
            agentState: AgentConnectionState?,
            initialTab: Int = TAB_AGENT_SETTINGS,
            onDismiss: (() -> Unit)? = null
        ): CovAgentTabDialog {
            return CovAgentTabDialog().apply {
                this.onDismissCallback = onDismiss
                this.agentState = agentState
                this.initialTab = initialTab
            }
        }
    }

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovAgentTabDialogBinding {
        return CovAgentTabDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding?.apply {
            setOnApplyWindowInsets(root)

            // Setup ViewPager2 with fragments
            setupViewPager()

            // Setup TabLayout with ViewPager2
            setupTabLayout()
        }
    }

    override fun disableDragging(): Boolean {
        // Disable swipe to dismiss
        return true
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        // Clean up animation resources
        tabIndicatorAnimator?.cancel()
        tabIndicatorAnimator = null
        onDismissCallback?.invoke()
    }

    private fun setupViewPager() {
        binding?.apply {
            val adapter = InfoTabPagerAdapter(this@CovAgentTabDialog)
            vpContent.adapter = adapter

            // Enable swiping for ViewPager2 to support horizontal sliding
            vpContent.isUserInputEnabled = true

            // Add page change callback to sync with tab indicator
            vpContent.registerOnPageChangeCallback(object : androidx.viewpager2.widget.ViewPager2.OnPageChangeCallback() {
                override fun onPageSelected(position: Int) {
                    super.onPageSelected(position)
                    // Sync TabLayout selection
                    tabLayout.getTabAt(position)?.select()
                    // Ensure indicator scale is reset to normal when page is fully selected
                    binding?.vTabIndicator?.scaleX = 1f
                }

                override fun onPageScrolled(position: Int, positionOffset: Float, positionOffsetPixels: Int) {
                    super.onPageScrolled(position, positionOffset, positionOffsetPixels)
                    // Smooth indicator movement during swipe with scale effect
                    if (tabWidth > 0) {
                        val indicatorX = (position + positionOffset) * tabWidth
                        binding?.vTabIndicator?.translationX = indicatorX

                        // Add scale effect during swipe: shrink when in the middle, normal at edges
                        // positionOffset ranges from 0 to 1, we want minimum scale at 0.5
                        val scaleProgress = kotlin.math.abs(positionOffset - 0.5f) * 2f // 0 at middle, 1 at edges
                        val minScale = 0.6f
                        val scale = minScale + (1f - minScale) * scaleProgress
                        binding?.vTabIndicator?.scaleX = scale
                    }
                }
            })

            // Set offscreen page limit to keep both fragments alive
            vpContent.offscreenPageLimit = 2
        }
    }

    private fun setupTabLayout() {
        binding?.apply {
            // Create custom tab layout with icons and text
            setupCustomTabs()

            // Handle tab selection
            tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
                override fun onTabSelected(tab: TabLayout.Tab?) {
                    tab?.let {
                        // Only set ViewPager position if not currently swiping (to avoid conflicts)
                        if (vpContent.currentItem != it.position) {
                            // Start custom animation with scale effect, then switch page
                            vpContent.setCurrentItem(it.position, true)
                        }
                        updateTabAppearance(it.position)
                    }
                }

                override fun onTabUnselected(tab: TabLayout.Tab?) {
                    tab?.let {
                        updateTabAppearance(it.position)
                    }
                }

                override fun onTabReselected(tab: TabLayout.Tab?) {
                    // Do nothing
                }
            })

            // Set default selected tab to Agent Settings (as shown in design)
            tabLayout.post {
                tabLayout.getTabAt(initialTab)?.select()
                vpContent.setCurrentItem(initialTab, false)
            }
        }
    }

    private fun setupCustomTabs() {
        binding?.apply {
            tabLayout.post {
                val tabCount = 2
                tabWidth = tabLayout.width / tabCount

                val channelInfoTab = tabLayout.newTab()
                val agentSettingsTab = tabLayout.newTab()

                val channelInfoView = createTabView(
                    io.agora.scene.common.R.drawable.scene_detail_wifi,
                    getString(R.string.cov_channel_info_title),
                    tabWidth
                )
                val agentSettingsView = createTabView(
                    io.agora.scene.common.R.drawable.scene_detail_setting,
                    getString(R.string.cov_setting_title),
                    tabWidth
                )

                channelInfoTab.customView = channelInfoView
                agentSettingsTab.customView = agentSettingsView

                tabLayout.removeAllTabs()
                tabLayout.addTab(agentSettingsTab)
                tabLayout.addTab(channelInfoTab)

                // Remove tab padding and minWidth for each tab
                val tabStrip = tabLayout.getChildAt(0) as? LinearLayout
                if (tabStrip != null) {
                    for (i in 0 until tabStrip.childCount) {
                        val tab = tabStrip.getChildAt(i)
                        tab.setPadding(0, 0, 0, 0)
                        tab.minimumWidth = 0
                    }
                }

                // Initialize tab indicator
                initializeTabIndicator()
            }
        }
    }

    private fun createTabView(iconRes: Int, text: String, width: Int): View {
        val tabView = LayoutInflater.from(context).inflate(R.layout.cov_custom_tab_item, null)
        tabView.layoutParams = ViewGroup.LayoutParams(width, ViewGroup.LayoutParams.MATCH_PARENT)
        val iconView = tabView.findViewById<ImageView>(R.id.ivTabIcon)
        val textView = tabView.findViewById<TextView>(R.id.tvTabText)
        iconView.setImageResource(iconRes)
        textView.text = text
        return tabView
    }

    private fun updateTabAppearance(selectedPosition: Int) {
        binding?.apply {
            val context = context ?: return
            for (i in 0 until tabLayout.tabCount) {
                val tab = tabLayout.getTabAt(i)
                val isSelected = i == selectedPosition

                tab?.customView?.let { tabView ->
                    val iconView = tabView.findViewById<ImageView>(R.id.ivTabIcon)
                    val textView = tabView.findViewById<TextView>(R.id.tvTabText)

                    if (isSelected) {
                        // Selected state: white text and icon (background handled by sliding indicator)
                        tabView.background = null
                        textView.setTextColor(
                            ContextCompat.getColor(
                                context,
                                io.agora.scene.common.R.color.ai_brand_white10
                            )
                        )
                        iconView.setColorFilter(
                            ContextCompat.getColor(
                                context,
                                io.agora.scene.common.R.color.ai_brand_white10
                            )
                        )
                    } else {
                        // Unselected state: transparent background, semi-transparent white text and icon
                        tabView.background = null
                        textView.setTextColor(
                            ContextCompat.getColor(context, io.agora.scene.common.R.color.ai_icontext2)
                        )
                        iconView.setColorFilter(
                            ContextCompat.getColor(context, io.agora.scene.common.R.color.ai_icontext2)
                        )
                    }
                }
            }
        }
    }

    /**
     * Initialize the tab indicator position and visibility
     */
    private fun initializeTabIndicator() {
        binding?.apply {
            vTabIndicator.layoutParams = vTabIndicator.layoutParams.apply {
                width = tabWidth
            }

            // Position indicator at the initial tab
            vTabIndicator.translationX = initialTab * tabWidth.toFloat()
            vTabIndicator.visibility = View.VISIBLE
        }
    }

    /**
     * Animate tab indicator with scale effect
     * First shrinks to 70%, then moves to target position, finally scales back to 100%
     */
    private fun animateTabIndicatorWithScale(targetPosition: Int) {
        binding?.apply {
            // Cancel any existing animation
            tabIndicatorAnimator?.cancel()

            val currentX = vTabIndicator.translationX
            val targetX = targetPosition * tabWidth.toFloat()

            // Create animator for the complete sequence
            tabIndicatorAnimator = ValueAnimator.ofFloat(0f, 1f).apply {
                duration = 300 // Total animation duration

                addUpdateListener { animator ->
                    val progress = animator.animatedValue as Float

                    when {
                        // Phase 1: Scale down (0% - 30% of animation)
                        progress <= 0.3f -> {
                            val scaleProgress = progress / 0.3f
                            val scale = 1f - (scaleProgress * 0.3f) // Scale from 100% to 70%
                            vTabIndicator.scaleX = scale
                            // Keep position unchanged during initial scaling
                            vTabIndicator.translationX = currentX
                        }
                        // Phase 2: Move to target position (30% - 70% of animation)
                        progress <= 0.7f -> {
                            val moveProgress = (progress - 0.3f) / 0.4f
                            vTabIndicator.scaleX = 0.7f // Keep at 70% during movement

                            // Move from current position to target position
                            val moveX = currentX + (targetX - currentX) * moveProgress
                            vTabIndicator.translationX = moveX
                        }
                        // Phase 3: Scale back up (70% - 100% of animation)
                        else -> {
                            val scaleProgress = (progress - 0.7f) / 0.3f
                            val scale = 0.7f + (scaleProgress * 0.3f) // Scale from 70% to 100%
                            vTabIndicator.scaleX = scale
                            // Keep at target position during final scaling
                            vTabIndicator.translationX = targetX
                        }
                    }
                }

                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: android.animation.Animator) {
                        // Ensure final state is correct
                        vTabIndicator.scaleX = 1f
                        vTabIndicator.translationX = targetX

                        // Now switch the ViewPager2 page
                        vpContent.setCurrentItem(targetPosition, true)
                    }
                })

                start()
            }
        }
    }

    /**
     * Get reference to Channel Info fragment
     */
    fun getChannelInfoFragment(): CovAgentInfoFragment? {
        return (binding?.vpContent?.adapter as? InfoTabPagerAdapter)?.getFragmentAt(TAB_CHANNEL_INFO) as? CovAgentInfoFragment
    }

    /**
     * Get reference to Agent Settings fragment
     */
    fun getAgentSettingsFragment(): CovAgentSettingsFragment? {
        return (binding?.vpContent?.adapter as? InfoTabPagerAdapter)?.getFragmentAt(TAB_AGENT_SETTINGS) as? CovAgentSettingsFragment
    }

    fun updateConnectStatus(state: AgentConnectionState) {
        getChannelInfoFragment()?.updateConnectStatus(state)
        getAgentSettingsFragment()?.updateConnectStatus(state)
    }

    /**
     * ViewPager2 adapter for tab fragments
     */
    private inner class InfoTabPagerAdapter(fragment: Fragment) : FragmentStateAdapter(fragment) {

        private val fragments = mutableMapOf<Int, Fragment>()

        override fun getItemCount(): Int = 2

        override fun createFragment(position: Int): Fragment {
            val fragment = when (position) {
                TAB_AGENT_SETTINGS -> CovAgentSettingsFragment.newInstance(agentState)
                TAB_CHANNEL_INFO -> CovAgentInfoFragment.newInstance(agentState)
                else -> throw IllegalArgumentException("Invalid position: $position")
            }
            fragments[position] = fragment
            return fragment
        }

        fun getFragmentAt(position: Int): Fragment? = fragments[position]
    }
}