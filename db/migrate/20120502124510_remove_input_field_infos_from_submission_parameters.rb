class RemoveInputFieldInfosFromSubmissionParameters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      templates = SubmissionTemplate.all
      templates.each do |template|
        template.submission_parameters[:input_field_infos].detect { |x| x.key == 'library_type' }.parameters[:selection] << 'DSN_RNAseq'
        #template.save(false)
      end
    end
  end

  def self.down
  end
end
