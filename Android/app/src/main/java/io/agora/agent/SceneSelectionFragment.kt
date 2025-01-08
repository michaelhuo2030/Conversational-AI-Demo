package io.agora.agent

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.agent.databinding.FragmentSceneSelectionBinding
import io.agora.agent.databinding.SceneSelectionItemBinding

class SceneSelectionFragment : Fragment() {

    private val TAG = "SceneSelectionFragment"

    private val mViewBinding by lazy { FragmentSceneSelectionBinding.inflate(LayoutInflater.from(context)) }

    private lateinit var sceneListAdapter: SceneListAdapter

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        return mViewBinding.root
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupView()
    }

    private fun setupView() {
        sceneListAdapter = SceneListAdapter(requireContext())
        mViewBinding.rvSceneList.layoutManager = LinearLayoutManager(requireContext())
        mViewBinding.rvSceneList.adapter = sceneListAdapter
        sceneListAdapter.setScenes(listOf(
            SceneModel(
                R.drawable.scene_selection_conversation,
                getString(R.string.scenes_item_conversation_agent_title),
                getString(R.string.scenes_item_conversation_agent_info),
                LivingActivity::class.java
            ),
//            SceneModel(
//                R.drawable.scene_selection_v2v,
//                getString(R.string.scenes_item_v2v_title),
//                getString(R.string.scenes_item_v2v_info),
//                LivingActivity::class.java
//            ),
//            SceneModel(
//                R.drawable.scene_selection_digital,
//                getString(R.string.scenes_item_digital_human_title),
//                getString(R.string.scenes_item_digital_human_info),
//                LivingActivity::class.java
//            )
        ))
    }

    class SceneListAdapter(private val context: Context) : RecyclerView.Adapter<SceneListAdapter.SceneViewHolder>() {

        private val scenes: MutableList<SceneModel> = mutableListOf()

        fun setScenes(scenes: List<SceneModel>) {
            this.scenes.clear()
            this.scenes.addAll(scenes)
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): SceneViewHolder {
            val binding = SceneSelectionItemBinding.inflate(LayoutInflater.from(context), parent, false)
            return SceneViewHolder(binding)
        }

        override fun onBindViewHolder(holder: SceneViewHolder, position: Int) {
            val scene = scenes[position]
            holder.bind(scene)
        }

        override fun getItemCount(): Int {
            return scenes.size
        }

        inner class SceneViewHolder(private val binding: SceneSelectionItemBinding) : RecyclerView.ViewHolder(binding.root) {
            fun bind(scene: SceneModel) {
                binding.ivIcon.setImageResource(scene.imageRes)
                binding.tvTitle.text = scene.title
                binding.tvInfo.text = scene.info
                binding.root.setOnClickListener {
                    context.startActivity(Intent(context, scene.activityClass))
                }
            }
        }
    }
    
    data class SceneModel(
        val imageRes: Int,
        val title: String,
        val info: String,
        val activityClass: Class<*>
    )
}

